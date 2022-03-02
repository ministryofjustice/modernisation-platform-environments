#!/bin/bash
set -e

# Note use of $${} syntax in paces - this is because this file is being used as a terraform template so need to escape variable substitution

# some vars
ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/gridhome_1
memtotal_kb=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)

hugepages() {
    
    echo "+++Configuring hugepages..."
    
    local page_size_kb=2048
    local pages=$(expr $memtotal_kb / 2 / $page_size_kb)
    local memlock_limit=$(expr $pages \* $page_size_kb)

    # configure huge pages
    sed -ri 's/^vm.nr_hugepages.*$/vm.nr_hugepages='"$pages"'/' /etc/sysctl.conf
    sysctl -p

    # check pages, repeat if necessary, wait up to 5 minutes
    local pages_created
    local i=0
    while [[ "$i" -lt 5 ]]; do
        pages_created=$(awk '/^HugePages_Total/ {print $2}' /proc/meminfo)
        if [[ "$pages_created" -ge "$pages" ]]; then
            break
        fi
        sleep 60
        sysctl -p
        ((i++))
    done
    
    echo "created [$pages_created/$pages] hugepages"

    # update memory limits
    sed -ri '/^\*[^0-9]+/ s/[0-9]+/'"$memlock_limit"'/' /etc/security/limits.d/99-grid-oracle-limits.conf
}

swap_disk() {

    echo "+++Configuring swap partition..."
    
    # get current swap partition
    local swap_disk=$(awk '/partition/ {print $1}' /proc/swaps)
    
    # set a label for swap partition
    local swap_label="swap"

    swapoff "$swap_disk"
    mkswap "$swap_disk" -L "$swap_label"

    # update fstab
    sed -ri "/^UUID=.*swap/ s/^UUID=\S+/LABEL=$swap_label/" /etc/fstab

    # activate swap
    swapon LABEL="$swap_label"
}

disks() {
    
    echo "+++Resizing existing ASM disks..."
    # find the oracleasm partitions
    IFS=$'\n'
    local devices=($(lsblk -npf -o FSTYPE,PKNAME | awk '/oracleasm/ {print $2}'))
    unset IFS

    for item in "$${devices[@]}"; do
        echo "resizing device $${item}"
        parted --script "$${item}" resizepart 1 100%
    done

    oracleasm scandisks # rediscover oracleasm disks before starting HAS
}

reconfigure_oracle_has() {
    
    echo "+++Reconfiguring Oracle HAS..."

    # kill anything on port 1521
    fuser -k -n tcp 1521 || true

    # update hostname in listener file
    sed -ri "s/(HOST = )([^\)]*)/\1$HOSTNAME/" $ORACLE_HOME/network/admin/listener.ora

    $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/perl/lib -I $ORACLE_HOME/crs/install $ORACLE_HOME/crs/install/roothas.pl

    # script to be run as oracle user
    cat > /tmp/oracle_reconfig.sh << 'EOF'
        #!/bin/bash

        echo "+++Setting up Oracle HAS as Oracle user"

        # retrieve password from parameter store
        password_ASMSYS=$(aws ssm get-parameter --with-decryption --name "${SSM_PARAMETER_ASMSYS}" --output text --query Parameter.Value)
        password_ASMSNMP=$(aws ssm get-parameter --with-decryption --name "${SSM_PARAMETER_ASMSNMP}" --output text --query Parameter.Value)
        
        # reconfigure Oracle HAS
        source oraenv <<< +ASM
        srvctl add listener
        spfile=$(adrci exec="set home +asm ; show alert -tail 1000" | grep -oE -m 1 '\+ORADATA.*') # get spfile for ASM
        srvctl add asm -l LISTENER -p "$spfile" -d "ORCL:ORA*"
        crsctl modify resource "ora.asm" -attr "AUTO_START=1"
        crsctl modify resource "ora.cssd" -attr "AUTO_START=1"
        crsctl stop has
        crsctl enable has
        crsctl start has
        sleep 10
        
        # wait for HAS to come up, particuarly ASM
        i=0
        while [[ "$i" -le 10 ]]; do
            asm_status=$(srvctl status asm | grep "ASM is running")
            if [[ -n "$asm_status" ]]; then
                asmcmd mount -a # returns exit code zero even if already mounted
               
                # resize data disks
                sqlplus -s / as sysasm <<< "alter diskgroup ORADATA resize all;"
                
                # set asm passwords
                asmcmd orapwusr --modify --password ASMSNMP <<< "$password_ASMSNMP"
                asmcmd orapwusr --modify --password SYS <<< "$password_ASMSYS"
                
                # start test database if present in AMI
                if [[ -n "$(grep CNOMT1 /etc/oratab)" ]]; then
                    source oraenv <<< CNOMT1
                    srvctl add database -d CNOMT1 -o $ORACLE_HOME
                    srvctl start database -d CNOMT1
                fi
                break
            fi
            if [[ "$i" -eq 10 ]]; then
                echo "The ASM disks could not be re-sized as the ASM service was not ready after 5 minutes"
                break
            fi
            sleep 30
            ((i++))
        done
EOF

    # run the script as oracle user
    chown oracle:oinstall /tmp/oracle_reconfig.sh
    chmod u+x /tmp/oracle_reconfig.sh
    echo "+++running reconfiguration script as oracle user"
    su - oracle -c /tmp/oracle_reconfig.sh

}

add_asm_disks() {
    # this function will use asmlib to mark a disk as an ASM disk then create and run a script as oracle user to add the disk
    # usage add_asm_disk <disk group name> <string of pipe separated disk volume ids>
    
    local disk_group="$1"
    local volume_ids="$2"

    # put the volume ids into an array
    IFS='|'
    read -a volume_ids_array <<< "$volume_ids"
    unset IFS

    echo "+++Creating additional ASM disks for disk group $disk_group..."
    # get the name corrsponding to the volume id of the device, partition and create asm disk
    local disks_added="" # this will hold a string of comma separated disks to be passed to the oracle user script and will form part of a sql statement
    local i=3 # TODO: add code to check next available group index, e.g ORADATA0* (01 and 02 included in AMI), also might need more than 9!
    for item in "$${volume_ids_array[@]}"; do
        local device_name=$(lsblk -ndp -o NAME,SERIAL | awk -v pattern="$item" '$0 ~ pattern {print $1}')
        # catch error that can occur if the disk is already an ASM disk (can occur when updating an AMI whilst keeping existing ASM disks)
        local is_asm_disk=$(oracleasm querydisk "$${device_name}p1" | grep "is not marked as an ASM disk")
        if [[ -n "$is_asm_disk" ]]; then
            parted --script "$device_name" mklabel gpt mkpart primary 1 100%
            oracleasm createdisk "$${disk_group}0$${i}" "$${device_name}p1"
            disks_added+="'ORCL:$${disk_group}0$${i}',"
        else
            echo "$device_name is already marked as an ASM disk"
        fi
        ((i++))
    done

    if [[ -n "$disks_added" ]]; then
        
        # prepare script to be run as oracle user
        cat > /tmp/oracle_add_disks.sh << 'EOF'
            #!/bin/bash            
            # usage: add_to_disk_group <disk group name> <partial sql query string that can be appended after DISK statement>
            
            source oraenv <<< +ASM

            local disk_group="$1"
            local sql_string="$2"

            # Set disk search string
            sqlplus -s / as sysasm <<< "alter system set asm_diskstring='ORCL:*';"
                      
            # add disks, but check for existing group
            local group_exists=$(asmcmd ls | grep "$disk_group")
            if [[ -z "$group_exists" ]]; then
                sqlplus -s / as sysasm <<< "create diskgroup "$disk_group" external redundancy disk "$sql_string";"
            else
                sqlplus -s / as sysasm <<< "alter diskgroup "$disk_group" add disk "$sql_string";"
            fi
EOF
        # run the script as oracle user
        chown oracle:oinstall /tmp/oracle_add_disks.sh
        chmod u+x /tmp/oracle_add_disks.sh
        echo "+++running add ASM disk script as oracle user"
        su - oracle -c /tmp/oracle_add_disks.sh "$disk_group" "$${disks_added%?}" # we need to trim the trailing comma from list of disks
    fi
}

main() {
    hugepages
    swap_disk
    disks
    reconfigure_oracle_has
    # create any additional Oracle ASM disks not included in AMI
    # var is templated from terraform as a single string of pipe separated values containing the volume id of the disks to be added
    if [[ -n "${ASM_DATA_DISKS}" ]]; then  
        add_asm_disks "ORADATA" "${ASM_DATA_DISKS}"
    fi

    if [[ -n "${ASM_FLASH_DISKS}" ]]; then  
        add_asm_disks "ORAFLASH" "${ASM_FLASH_DISKS}"
    fi    
}

main
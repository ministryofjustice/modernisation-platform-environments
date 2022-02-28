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
    
    echo "+++Resizing ASM disks..."
    # find the oracleasm partitions
    IFS=$'\n'
    local devices=($(lsblk -npf -o FSTYPE,PKNAME | awk '/oracleasm/ {print $2}'))
    unset IFS

    for item in "$${devices[@]}"; do
        echo "resizing device $${item}"
        parted --script "$${item}" resizepart 1 100%
    done
    
    # create any additional Oracle ASM disks not included in AMI
    # var is passed from terraform as a single string of pipe separated values.  Read into an array
    IFS='|'
    read -a asm_disk_array <<< "${asm_disks}"
    unset IFS

    # get the name corrsponding to the volume id of the device, partition and create asm disk
    local i=3 # TODO: add code to check next available ORADATA0* (01 and 02 included in AMI)
    for item in "$${asm_disk_array[@]}"; do
        local device_name=$(lsblk -ndp -o NAME,SERIAL | awk -v pattern="$item" '$0 ~ pattern {print $1}')
        # catch error that can occur if the disk is already an ASM disk (can occur when updating an AMI whilst keeping existing ASM disks)
        is_asm_disk=$(oracleasm querydisk "$${device_name}p1" | grep "is not marked as an ASM disk")
        if [[ -n "$is_asm_disk" ]]; then
            parted --script "$device_name" mklabel gpt mkpart primary 1 100%
            oracleasm createdisk "ORADATA0$${i}" "$${device_name}p1"
        fi
        ((i++))
    done

    # rediscover oracleasm disk before proceeding
    oracleasm scandisks
}

reconfigure_oracle_has() {
    
    echo "+++Reconfiguring Oracle HAS..."

    # kill anything on port 1521
    fuser -k -n tcp 1521 || true

    # update hostname in listener file
    sed -ri "s/(HOST = )([^\)]*)/\1$HOSTNAME/" $ORACLE_HOME/network/admin/listener.ora

    echo "+++reconfigure grid"
    $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/perl/lib -I $ORACLE_HOME/crs/install $ORACLE_HOME/crs/install/roothas.pl

    # script to be run as oracle user
    cat > /tmp/oracle_reconfig.sh << 'EOF'
        #!/bin/bash

        # retrieve password from parameter store
        password_ASMSYS=$(aws ssm get-parameter --with-decryption --name "${parameter_name_ASMSYS}" --output text --query Parameter.Value)
        password_ASMSNMP=$(aws ssm get-parameter --with-decryption --name "${parameter_name_ASMSNMP}" --output text --query Parameter.Value)
        
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
                asmcmd mount ORADATA # returns exit code zero even if already mounted
                
                # add any new ASM disks
                oracleasm_disks=$(oracleasm listdisks) # all available asm disks
                disk_group_disks=$(asmcmd lsdsk -G ORADATA --suppressheader | awk -F ':' '{print $2}') # disks already members of disk group
                unique=($(echo "$disk_group_disks" "$oracleasm_disks" | tr ' ' '\n' | sort | uniq -u)) # disks not in disk group, kind of
                for j in "$${unique[@]}"; do
                    sqlplus -s / as sysasm <<< "alter diskgroup ORADATA add disk 'ORCL:$${j}';"
                done
                
                # resize disks
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

main() {
    hugepages
    swap_disk
    disks
    reconfigure_oracle_has
}

main
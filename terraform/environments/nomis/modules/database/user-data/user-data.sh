#!/bin/bash
# Note use of $${} syntax in places - this is because this file is being used as a terraform template so need to escape variable substitution
set -euo pipefail

hugepages() {

    echo "+++Configuring hugepages..."

    local memtotal_kb=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)

    local page_size_kb=2048
    local pages=$(expr $memtotal_kb / 2 / $page_size_kb)

    local memlock=$(expr 9 \* $memtotal_kb / 10)
    local memlock_max=134217728 # 128GB
    local memlock_limit=$(( $memlock > $memlock_max ? $memlock_max : $memlock ))

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

    # update memlock limits
    sed -ri '/^oracle.+memlock[^0-9]+/ s/[0-9]+/'"$memlock_limit"'/' /etc/security/limits.conf
}

swap_disk() {
    echo "+++Updating PATH with /usr/local/bin for aws-cli"
    local PATH=$PATH:/usr/local/bin

    echo "+++Waiting for volumes to be attached to instance"
    aws ec2 wait volume-in-use --volume-ids ${volume_ids}

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

    echo "+++Resizing Oracle application disks"
    xfs_growfs -d /u01
    xfs_growfs -d /u02

    echo "+++Resizing ASM disks..."
    # find the oracleasm partitions
    IFS=$'\n'
    local devices=($(lsblk -npf -o FSTYPE,PKNAME | awk '/oracleasm/ {print $2}'))
    unset IFS

    for item in "$${devices[@]}"; do
        echo "resizing device $${item}"
        parted --script "$${item}" resizepart 1 100%
    done

    # rescan oracle asm disks as they don't always appear on first launch of instance
    oracleasm scandisks
}

reconfigure_oracle_has() {

    local ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/gridhome_1

    echo "+++Reconfiguring Oracle HAS..."

    # kill anything on port 1521
    fuser -k -n tcp 1521 || true

    # update hostname in listener file
    sed -ri "s/(HOST = )([^\)]*)/\1$HOSTNAME/" $ORACLE_HOME/network/admin/listener.ora
    %{ if restored_from_snapshot } # if restoring from existing oracle database snapshot

    echo "+++deconfigure existing grid infrastructure"
    $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/perl/lib -I $ORACLE_HOME/crs/install $ORACLE_HOME/crs/install/roothas.pl -deconfig -force

    %{ endif }

    echo "+++reconfigure grid"
    $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/perl/lib -I $ORACLE_HOME/crs/install $ORACLE_HOME/crs/install/roothas.pl

    # script to be run as oracle user
    cat > /tmp/oracle_reconfig.sh << 'EOF'
        #!/bin/bash
        echo "+++Setting up Oracle HAS as Oracle user"

        # retrieve password from parameter store
        password_ASMSYS=$(aws ssm get-parameter --with-decryption --name "${parameter_name_ASMSYS}" --output text --query Parameter.Value)
        password_ASMSNMP=$(aws ssm get-parameter --with-decryption --name "${parameter_name_ASMSNMP}" --output text --query Parameter.Value)

        # reconfigure Oracle HAS
        source oraenv <<< +ASM
        srvctl add listener
        # get spfile for ASM
        spfile=$(adrci exec="set home +asm ; show alert -tail 1000" | grep -oE -m 1 '\+ORADATA.*')
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
                asmcmd mount DATA # returns exit code zero even if already mounted
                asmcmd mount FLASH

                # resize disks
                sqlplus -s / as sysasm <<< "alter diskgroup DATA resize all;"
                sqlplus -s / as sysasm <<< "alter diskgroup FLASH resize all;"

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
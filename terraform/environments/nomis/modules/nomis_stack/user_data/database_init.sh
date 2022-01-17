#!/bin/bash
set -e

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

    # check pages
    local pages_created=$(awk '/^HugePages_Total/ {print $2}' /proc/meminfo)

    # repeat if necessary, wait up to 5 minutes
    local i=0
    while [[ "$i" -lt 5 ]]; do
        if [[ "$pages_created" -ge "$pages" ]]; then
            break
        fi
        sleep 60
        sysctl -p
        pages_created=$(awk '/^HugePages_Total/ {print $2}' /proc/meminfo)
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

    # Note use of $${} syntax - this is because this file is being used as a terraform template
    # so we need the extra $ to prevent terraform trying to interpolate it
    for item in "$${devices[@]}"; do
        echo "resizing device $${item}"
        parted --script "$${item}" resizepart 1 100%
    done

    # rescan oracle asm disks as they don't always appear on first launch of instance
    oracleasm scandisks
}

reconfigure_oracle_has() {
    
    echo "+++Reconfiguring Oracle HAS..."

    # kill anything on port 1521
    fuser -k -n tcp 1521 || true

    # update hostname in listener file
    sed -ri "s/(HOST = )([^\)]*)/\1$HOSTNAME/" /u01/app/oracle/product/11.2.0.4/gridhome_1/network/admin/listener.ora

    echo "+++reconfigure grid"
    $ORACLE_HOME/perl/bin/perl -I $ORACLE_HOME/perl/lib -I $ORACLE_HOME/crs/install $ORACLE_HOME/crs/install/roothas.pl

    # script to be run as oracle user
    cat > /tmp/oracle_reconfig.sh << 'EOF'
        #!/bin/bash
        password_ASMSYS=$(aws ssm get-parameter --with-decryption --name "${parameter_name_ASMSYS}" --output text --query Parameter.Value)
        password_ASMSNMP=$(aws ssm get-parameter --with-decryption --name "${parameter_name_ASMSNMP}" --output text --query Parameter.Value)
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
        i=0
        asm_status=$(srvctl status asm | grep "ASM is running")
        while [[ "$i" -le 10 ]]; do
            if [[ -n "$asm_status" ]]; then
                asmcmd mount ORADATA
                sqlplus -s / as sysasm <<< "alter diskgroup ORADATA resize all;"
                asmcmd orapwusr --modify --password ASMSNMP <<< "$password_ASMSNMP"
                asmcmd orapwusr --modify --password ASMSYS <<< "$password_ASMSYS"
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
            asm_status=$(srvctl status asm | grep "ASM is running")
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
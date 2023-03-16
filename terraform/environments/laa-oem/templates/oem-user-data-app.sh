#!/usr/bin/env bash

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y awscli jq telnet

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

groupadd oinstall
useradd -g oinstall applmgr

# /                   12    gp3 3000
# swap                32    gp3      /dev/sdb
# /opt/oem/app        50    gp3 3000 /dev/sdc
# /opt/oem/inst       50    gp3 3000 /dev/sdd
# /opt/oem/backups    EFS

EHOSTS=/etc/hosts
FSTAB=/etc/fstab
MOUNT_DIR=/opt

declare -A MOUNTS=(
    [/dev/sdb]="swap"
    [/dev/sdc]="APP"
    [/dev/sdd]="INST"
)

declare -A NVMES=()
for n in /dev/nvme*n1; do
    D=$(ebsnvme-id $${n} |grep -v 'Volume ID')
    if [[ -n $${D} ]]; then
        if [[ $${D} =~ /dev ]]; then
            NVMES[$${D}]=$${n}
        else
            NVMES[/dev/$${D}]=$${n}
        fi
    fi
done

#for k in $${!NVMES[@]}; do
#    v=$${NVMES[$${k}]}
#    echo "$${k} : $${v}"
#done
#
# /dev/sdd : /dev/nvme3n1
# /dev/sdb : /dev/nvme2n1
# /dev/sdc : /dev/nvme1n1

for M in $${!MOUNTS[@]}; do
    L=$${MOUNTS[$${M}]}
    N=$${NVMES[$${M}]}
    if [[ -n $${N} ]]; then
#       echo "$${M} -> $${N} as $${L}"
        if [[ $${L} == "swap" ]]; then
            swapoff -a
            mkswap -L $${L} $${M}
            swapon -L $${L}
            echo "LABEL=$${L} swap swap defaults 0 0" >> $${FSTAB}
        else
            FS_DIR=$${MOUNT_DIR}/oem/$${L,,}
            if [[ ! $(mount -t ext4,xfs |grep "$${FS_DIR}") ]]; then
                mkdir -p $${FS_DIR}
#               yes |mkfs.ext4 -qL $${L} $${M} # We are using snapshots now, so don't erase the volume.
                echo "LABEL=$${L} $${FS_DIR} ext4 defaults 0 0" >> $${FSTAB}
                mount -L $${L}
            else
                echo "$${FS_DIR} is already mounted:"
                mount -t ext4,xfs |grep "$${FS_DIR}"
            fi
        fi
    fi
done

# File Permissions
chown -R oracle:dba $${MOUNT_DIR}

# Mount shared disk
FS_DIR=$${MOUNT_DIR}/oem/backups
mkdir -p $${FS_DIR}
chmod go+rw $${FS_DIR}
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_fqdn}:/ $${FS_DIR}
echo "${efs_fqdn}:/ $${FS_DIR} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> $${FSTAB}

hostnamectl set-hostname ${hostname}

H=$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" > $${EHOSTS}.new
echo "$${H} ${hostname} ${hostname}.${env_fqdn}" >> $${EHOSTS}.new
mv $${EHOSTS}.new $${EHOSTS}
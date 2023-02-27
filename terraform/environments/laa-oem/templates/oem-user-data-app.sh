#!/usr/bin/env bash

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y jq telnet

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

groupadd oinstall
useradd -g oinstall applmgr

# /                12    gp3 3000
# swap             32    gp3      /dev/sdb
# /oem/app         50    gp3 3000 /dev/sdc
# /oem/inst        50    gp3 3000 /dev/sdd

FSTAB=/etc/fstab
MOUNT_DIR=/mnt

declare -A MOUNTS=(
    [/dev/sdb]="swap"
    [/dev/sdc]="APP"
    [/dev/sdd]="INST"
)

declare -A NVMES=()
for n in /dev/nvme*n1; do
    D=$(ebsnvme-id $${n} |grep '^/dev')
    if [[ -n $${D} ]]; then
        NVMES[$${n}]=$${D}
    fi
done

#for k in $${!NVMES[@]}; do
#    v=$${NVMES[$${k}]}
#    echo "$${k} : $${v}"
#done
#
# /dev/nvme3n1 : /dev/sdd
# /dev/nvme2n1 : /dev/sdb
# /dev/nvme1n1 : /dev/sdc

for n in $${!NVMES[@]}; do
    D=$${NVMES[$${n}]}
    L=$${MOUNTS[$${D}]}
#   echo "Mount $${D} as $${L}"
    if [[ $${L} == "swap" ]]; then
        swapoff -a
        mkswap -L $${L} $${D}
        swapon -L $${L}
        echo "LABEL=$${L} swap swap defaults 0 0" >> $${FSTAB}
    else
        FS_DIR=$${MOUNT_DIR}/oem/$${L,,}
        mkdir -p $${FS_DIR}
        mkfs.ext4 -L $${L} $${D}
        echo "LABEL=$${L} $${FS_DIR} ext4 defaults 0 0" >> $${FSTAB}
        mount -L $${L}
    fi
done

# File Permissions
chown -R oracle:dba $${MOUNT_DIR}

# Mount shared disk
FS_DIR=$${MOUNT_DIR}/oem/shared
mkdir -p $${FS_DIR}
chmod go+rw $${FS_DIR}
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.eu-west-2.amazonaws.com:/ $${FS_DIR}
echo "${efs_id}.eu-west-2.amazonaws.com:/ $${FS_DIR} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> $${FSTAB}

# Set hostname
hostnamectl set-hostname ${hostname}

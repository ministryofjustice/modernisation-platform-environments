#!/usr/bin/env bash

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y jq telnet

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

groupadd oinstall
useradd -g oinstall applmgr

# /                    12    gp3 3000
# swap                 32    gp3      /dev/sdb
# /oem/app             50    gp3 3000 /dev/sdc
# /oem/inst            50    gp3 3000 /dev/sdd
# /oem/dbf            200    io2 3000 /dev/sde
# /oem/redo            20    io2 3000 /dev/sdf
# /oem/archive        200    io2 3000 /dev/sdg
# /opt/oem/backups    EFS

FSTAB=/etc/fstab
MOUNT_DIR=/opt

declare -A MOUNTS=(
    [/dev/sdb]="swap"
    [/dev/sdc]="APP"
    [/dev/sdd]="INST"
    [/dev/sde]="DBF"
    [/dev/sdf]="REDO"
    [/dev/sdg]="ARCH"
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
# /dev/sdf : /dev/nvme5n1
# /dev/sdg : /dev/nvme6n1
# /dev/sdd : /dev/nvme1n1
# /dev/sde : /dev/nvme2n1
# /dev/sdb : /dev/nvme3n1
# /dev/sdc : /dev/nvme4n1
# /dev/sda1 : /dev/nvme0n1

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
                yes |mkfs.ext4 -qL $${L} $${M}
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
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.eu-west-2.amazonaws.com:/ $${FS_DIR}
echo "${efs_id}.eu-west-2.amazonaws.com:/ $${FS_DIR} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> $${FSTAB}

# Set hostname
hostnamectl set-hostname ${hostname}

# Update /etc/hosts
H=$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')
echo "${H} ${hostname} ${hostname}.dev.legalservices.gov.uk" >> /etc/hosts
#!/usr/bin/env bash

B=/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
S=/etc/pki/ca-trust/source
if command -v openssl >/dev/null 2>&1; then
  echo "openssl is available."
else
  echo "openssl is not available, exiting."
  exit 1
fi
if [[ ! -f $B ]]; then
  echo "Not found: $B, exiting."
  exit 1
fi
if [[ -d "$S/blacklist" ]]; then
  L=$S/blacklist
  V="a"
elif [[ -d "$S/blocklist" ]]; then
  L=$S/blocklist
  V="o"
else
  echo "ERROR: no blacklist/blocklist directory under $S" >&2
  exit 1
fi
echo "Using $L"
D=$(mktemp -d)
cd "$D"
csplit -s -z -f cert- "$B" '/-----BEGIN TRUSTED CERTIFICATE-----/' '{*}'
for f in cert-*; do
  echo -n "Processing: $f ... "
  O=$(openssl x509 -noout -subject -in "$f"  2>/dev/null |grep -iE 'cn=(aaa|emsign|emudhra)')
  if [[ -n $O ]]; then
    echo "dirty."
    F=$(openssl x509 -in "$f" -noout -fingerprint -sha256 |cut -d= -f2 | tr -d :)
    N=$(grep -oP 'CN=\K[^,]+' <<< $O |tr \\040 \\137)
    openssl x509 -in "$f" -out "$L/$N-$F.pem"
    echo "Extracted and added to the block list: $(openssl x509 -in "$f" -noout -subject)"
  else
    echo "clean."
  fi
done
echo
ls -l $L |grep '\.pem'
echo
for f in $L/*.pem; do
  echo -n "$(basename $f): "
  openssl x509 -in "$f" -noout -subject 2>/dev/null
done
echo -e "\nRunning extraction.\n"
update-ca-trust extract
echo "Run these commands now:"
echo "trust list --filter=bl${V}cklist"
echo "curl -v https://dv-g3b-emudhra.we-have-a-problem.com/"
echo
cd / && rm -rf "$D"

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y awscli jq telnet

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

groupadd oinstall
useradd -g oinstall applmgr

# /                    12    gp3 3000
# swap                 32    gp3      /dev/sdb
# /opt/oem/app         50    gp3 3000 /dev/sdc
# /opt/oem/inst        50    gp3 3000 /dev/sdd
# /opt/oem/dbf        200    io2 3000 /dev/sde
# /opt/oem/redo        20    io2 3000 /dev/sdf
# /opt/oem/arch       200    io2 3000 /dev/sdg
# /opt/oem/backups    EFS

EFSTAB=/etc/fstab
EHOSTS=/etc/hosts
ERCONF=/etc/resolv.conf
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
#           echo "LABEL=$${L} swap swap defaults 0 0" >> $${EFSTAB}
        else
            FS_DIR=$${MOUNT_DIR}/oem/$${L,,}
            if [[ ! $(mount -t ext4,xfs |grep "$${FS_DIR}") ]]; then
                mkdir -p $${FS_DIR}
#               yes |mkfs.ext4 -qL $${L} $${M} # We are using snapshots now, so don't erase the volume.
                echo "LABEL=$${L} $${FS_DIR} ext4 defaults 0 0" >> $${EFSTAB}
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
grep -v '/opt/oem/backups' $${EFSTAB} > $${EFSTAB}.new
echo "${efs_fqdn}:/ $${FS_DIR} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> $${EFSTAB}.new
mv $${EFSTAB}.new $${EFSTAB}
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_fqdn}:/ $${FS_DIR}

hostnamectl set-hostname ${hostname}

H=$(curl -s 'http://169.254.169.254/latest/meta-data/local-ipv4')
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" > $${EHOSTS}.new
echo "$${H} ${hostname} ${hostname}.${env_fqdn}" >> $${EHOSTS}.new
mv $${EHOSTS}.new $${EHOSTS}

sed -i "s/^search .*/search ${env_fqdn}/" $${ERCONF}
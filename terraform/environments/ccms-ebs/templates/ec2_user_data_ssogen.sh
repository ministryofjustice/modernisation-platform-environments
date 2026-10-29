#!/bin/bash

set -euo pipefail
#Logic for moving emudhra certs to blocked list
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
  if ! subject=$(openssl x509 -noout -subject -in "$f"  2>/dev/null); then
    echo "Skipping invalid certificate: $f" >&2
    continue
  echo $subject
  fi

  if echo "$subject" | grep -qiE 'cn=(aaa|emsign|emudhra)'; then
    echo "dirty."
    F=$(openssl x509 -in "$f" -noout -fingerprint -sha256 |cut -d= -f2 | tr -d :)
    N=$(grep -oP 'CN=\K[^,]+' <<< $subject |tr \\040 \\137)
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

# === Set hostname ===
hostnamectl set-hostname "${hostname}"

# === Configure resolv.conf ===
nmcli con modify "System eth0" ipv4.ignore-auto-dns no
nmcli con modify "System eth0" ipv4.dns-search "${mp_fqdn} eu-west-2.compute.internal"
nmcli con up "System eth0"
# === Base updates and packages ===
yum update -y

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:ssogen-cloud-watch-config

# Wait for disks to appear
sleep 25

IFS=',' read -r -a DISKS_ARRAY <<< "${DISKSARRAY}"

for entry in "$${DISKS_ARRAY[@]}"; do
  IFS=":" read -r disk mount <<< "$entry"
  echo "Processing $disk -> $mount"
  # Ensure directory exists
  mkdir -p "$mount"

  if [[ $mount != "/tmp" ]] ; then
    # Get UUID for persistent mount
    uuid=$(blkid -s UUID -o value "$${disk}")
    # Remove from fstab 
    sed -i "\|$mount|d" /etc/fstab
    # Add to fstab
    echo "Adding to /etc/fstab"
    echo "UUID=$uuid $mount xfs defaults,nofail 0 2" >> /etc/fstab
  fi
done

deploy_cortex() {
  CORTEX_DIR=/tmp/CortexAgent
  CORTEX_VERSION=linux_8_8_0_133595_rpm

  #--Prep
  mkdir -p $CORTEX_DIR/linux_8_8_0_133595_rpm
  mkdir /etc/panw
  aws s3 sync s3://ccms-shared/CortexAgent/ $CORTEX_DIR #--ccms-shared is in the EBS dev account 767123802783. Bucket is shared at the ORG LEVEL.
  tar zxf $CORTEX_DIR/$CORTEX_VERSION.tar.gz -C $CORTEX_DIR/$CORTEX_VERSION
  cp $CORTEX_DIR/$CORTEX_VERSION/cortex.conf /etc/panw/cortex.conf
  sed -i -e '$a\' /etc/panw/cortex.conf && echo "--endpoint-tags ccms,ssogen" >> /etc/panw/cortex.conf

  #--Installs
  yum install -y selinux-policy-devel
  rpm -Uvh $CORTEX_DIR/$CORTEX_VERSION/cortex-*.rpm
  systemctl status traps_pmd
  echo "Cortex Install Routine Complete. Installation Is NOT GUARANTEED -- Check Logs For Success"
}

if [[ "${deploy_environment}" = "production" ]]; then
  deploy_cortex
fi

#--Configure EFS
mkdir -p /mnt/efs
mount -t efs -o tls ${efs_id}:/ /mnt/efs
IFS=',' read -r -a EFS_MP_ARRAY <<< "${EFS_MOUNT_POINT_ARRAY}"

for var in "$${EFS_MP_ARRAY[@]}"; do
  IFS=":" read -r efsmount localmount <<< "$var"
  mkdir -p /mnt/efs/$efsmount
  mkdir -p $localmount
  mount -t efs -o tls ${efs_id}:/$efsmount $localmount
  chmod go+rw $localmount
  # create large file for better EFS performance 
  # https://docs.aws.amazon.com/efs/latest/ug/performance.html
  dd if=/dev/urandom of=$localmount/large_file_for_efs_performance bs=1024k count=10000
  echo "Removing existing mount point /etc/fstab"
  sed -i "\|$localmount|d" /etc/fstab
  echo "Adding to /etc/fstab"
  echo "${efs_id}:/$efsmount $localmount efs _netdev,tls,nofail 0 0" >> /etc/fstab
done

umount /mnt/efs
echo "SSOGEN instance bootstrap completed" >> /var/log/user-data.log
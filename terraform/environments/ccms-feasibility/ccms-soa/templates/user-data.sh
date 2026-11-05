#!/bin/bash
EC2_USER_HOME_FOLDER=/home/ec2-user
EFS_MOUNT_POINT=$EC2_USER_HOME_FOLDER/efs
INBOUND_S3_MOUNT_POINT=$EC2_USER_HOME_FOLDER/inbound
OUTBOUND_S3_MOUNT_POINT=$EC2_USER_HOME_FOLDER/outbound
DOMAIN_HOME=$EFS_MOUNT_POINT/domains/soainfra
CONFIG_LOCATION=$DOMAIN_HOME/config
WLS_NS="http://xmlns.oracle.com/weblogic/domain"

echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_ENABLE_CONTAINER_METADATA=true' >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config
echo 'ECS_INSTANCE_ATTRIBUTES={"server": "${server}","latest": "true"}' >> /etc/ecs/ecs.config

#--Configure EFS
yum install -y amazon-efs-utils
mkdir -p $EFS_MOUNT_POINT
mount -t efs -o tls ${efs_id}:/ $EFS_MOUNT_POINT
chmod go+rw $EFS_MOUNT_POINT
# create large file for better EFS performance (bursting throughput scales with stored size)
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
if [[ ! -f $EFS_MOUNT_POINT/large_file_for_efs_performance ]]; then
  dd if=/dev/urandom of=$EFS_MOUNT_POINT/large_file_for_efs_performance bs=1024k count=10000
fi

#--Tooling (AL2023: no amazon-linux-extras/EPEL; awscli v2 ships with the AMI)
dnf install -y git jq

# Configure SSH and pull git repo
mkdir -p $EC2_USER_HOME_FOLDER/.ssh
chown ec2-user:ec2-user $EC2_USER_HOME_FOLDER/.ssh
chmod 700 $EC2_USER_HOME_FOLDER/.ssh
su ec2-user bash -c 'aws secretsmanager get-secret-value --secret-id ${secret_id} --query SecretString --output text --region eu-west-2 | jq -r ".\"deploy-github-ssh-key\"" | base64 -d > /home/ec2-user/.ssh/id_rsa'
chown ec2-user:ec2-user $EC2_USER_HOME_FOLDER/.ssh/id_rsa
chmod 400 $EC2_USER_HOME_FOLDER/.ssh/id_rsa
cat <<EOF > $EC2_USER_HOME_FOLDER/.ssh/config
host ssh.github.com
  HostName ssh.github.com
  Port 443
  User git
StrictHostKeyChecking no
EOF
chown ec2-user:ec2-user $EC2_USER_HOME_FOLDER/.ssh/config
chmod 600 $EC2_USER_HOME_FOLDER/.ssh/config
su ec2-user bash -c "git clone ssh://git@ssh.github.com:443/ministryofjustice/laa-ccms-app-soa.git $EFS_MOUNT_POINT/laa-ccms-app-soa || git -C $EFS_MOUNT_POINT/laa-ccms-app-soa pull"

#--Populate custom monitoring files
su ec2-user bash -c "cp $EFS_MOUNT_POINT/laa-ccms-app-soa/monitoring/* $EFS_MOUNT_POINT/"

#--Mount the ccms-ebs inbound/outbound S3 buckets for SOA file-based integration
#--AL2023 has no s3fs-fuse package, so use Mountpoint for S3 (as laa-ccms-soa does)
sed -i '/^#.*user_allow_other/s/^#//' /etc/fuse.conf
dnf install -y mount-s3

mkdir -p $INBOUND_S3_MOUNT_POINT
mkdir -p $OUTBOUND_S3_MOUNT_POINT
chmod 777 $INBOUND_S3_MOUNT_POINT
chmod 777 $OUTBOUND_S3_MOUNT_POINT
chown -R 1000:1000 $INBOUND_S3_MOUNT_POINT
chown -R 1000:1000 $OUTBOUND_S3_MOUNT_POINT

mount-s3 ${inbound_bucket} $INBOUND_S3_MOUNT_POINT --allow-other --uid 1000 --gid 1000 --dir-mode 0777 --file-mode 0777
mount-s3 ${outbound_bucket} $OUTBOUND_S3_MOUNT_POINT --allow-other --uid 1000 --gid 1000 --dir-mode 0777 --file-mode 0777

#--Create essential subdirs in S3 Bucket
mkdir -p \
  $INBOUND_S3_MOUNT_POINT/archive \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Allpay \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Allpay/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Barclaycard \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Barclaycard/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_CCR \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_CCR/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Eckoh \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Eckoh/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Lloyds \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Lloyds/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_RBS \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_RBS/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_RBS/Inbound/BACKUP \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Rossendales \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Rossendales/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_Rossendales/archive \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_TDX \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_TDX/Inbound \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_TDX_DECRYPTED \
  $INBOUND_S3_MOUNT_POINT/CCMS_PRD_TDX_DECRYPTED/Inbound \
  $INBOUND_S3_MOUNT_POINT/error \
  $INBOUND_S3_MOUNT_POINT/inprocess \
  $INBOUND_S3_MOUNT_POINT/rejected

#--Clears all admin files and entries from config.xml on admin host only
reset_admin() {
  cp -p $CONFIG_LOCATION/config.xml $CONFIG_LOCATION/config.xml.$(date '+%Y%m%d-%H%M').bak
  cp -p $CONFIG_LOCATION/config.xml $CONFIG_LOCATION/config.xml.none

  xmlstarlet ed --inplace -N x="$WLS_NS" -d "//x:server[./x:name[contains(text(),'ccms_soa_ms')]]" $CONFIG_LOCATION/config.xml.none
  xmlstarlet ed --inplace -N x="$WLS_NS" -d "//x:machine[./x:name[contains(text(),'MACHINE-')]]" $CONFIG_LOCATION/config.xml.none
  xmlstarlet ed --inplace -N x="$WLS_NS" -d "//x:migratable-target[./x:name[contains(text(),'ccms_soa_ms')]]" $CONFIG_LOCATION/config.xml.none
  xmlstarlet ed --inplace -N x="$WLS_NS" -u "//x:coherence-cluster-system-resource/x:target" -v "AdminServer" $CONFIG_LOCATION/config.xml.none

  cp -p $CONFIG_LOCATION/config.xml.none $CONFIG_LOCATION/config.xml

  rm -rf $DOMAIN_HOME/original
  rm -rf $DOMAIN_HOME/pending
  rm -rf $DOMAIN_HOME/edit
  rm -f $DOMAIN_HOME/edit.lok
  rm -rf $DOMAIN_HOME/servers/domain_bak
  rm -rf $DOMAIN_HOME/servers/AdminServer/cache
  rm -rf $DOMAIN_HOME/servers/AdminServer/logs
  rm -rf $DOMAIN_HOME/servers/AdminServer/tmp
}

#--Configures config.xml to listen for Weblogic on HTTPS only (prevents https > http redirection loops). CC-3814
ensure_https() {
  PLUGIN_XPATH="//x:server[x:name='AdminServer']/x:web-server/x:weblogic-plugin-enabled"
  if xmlstarlet sel -N x="$WLS_NS" -t -c "$PLUGIN_XPATH" $CONFIG_LOCATION/config.xml | grep -q .; then
    xmlstarlet ed --inplace -N x="$WLS_NS" -u "$PLUGIN_XPATH" -v "true" $CONFIG_LOCATION/config.xml
  else
    xmlstarlet ed --inplace -N x="$WLS_NS" -s "//x:server[x:name='AdminServer']/x:web-server" -t elem -n "weblogic-plugin-enabled" -v "true" $CONFIG_LOCATION/config.xml
  fi
}

#--Domain lives on EFS; on a fresh EFS the container creates it on first start, so there is nothing to reset yet
if [[ "${server}" = "admin" && -f $CONFIG_LOCATION/config.xml ]]; then
  dnf install -y xmlstarlet
  ensure_https
  reset_admin
fi

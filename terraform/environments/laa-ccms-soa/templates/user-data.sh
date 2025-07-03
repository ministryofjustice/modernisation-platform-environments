#!/bin/bash
EC2_USER_HOME_FOLDER=/home/ec2-user
EFS_MOUNT_POINT=$EC2_USER_HOME_FOLDER/efs
INBOUND_S3_MOUNT_POINT=$EC2_USER_HOME_FOLDER/inbound
OUTBOUND_S3_MOUNT_POINT=$EC2_USER_HOME_FOLDER/outbound

echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config
echo 'ECS_INSTANCE_ATTRIBUTES={"server": "${server}","latest": "true"}' >> /etc/ecs/ecs.config

#--Configure EFS
yum install -y amazon-efs-utils
mkdir $EFS_MOUNT_POINT
mount -t efs -o tls ${efs_id}:/ $EFS_MOUNT_POINT
chmod go+rw $EFS_MOUNT_POINT
# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=$EFS_MOUNT_POINT/large_file_for_efs_performance bs=1024k count=10000

#--Add EPEL Repo
amazon-linux-extras install epel -y

#--Install AWSCLI
yum install -y awscli

# Configure SSH and pull git repo
yum install git -y
su ec2-user bash -c "aws secretsmanager get-secret-value --secret-id ccms/soa/deploy-github-ssh-key --query SecretString --output text --region eu-west-2 | base64 -d > /home/ec2-user/.ssh/id_rsa"
chown ec2-user $EC2_USER_HOME_FOLDER/.ssh/id_rsa
chgrp ec2-user $EC2_USER_HOME_FOLDER/.ssh/id_rsa
chmod 400 $EC2_USER_HOME_FOLDER/.ssh/id_rsa
cat <<EOF > $EC2_USER_HOME_FOLDER/.ssh/config
host ssh.github.com
  HostName ssh.github.com
  Port 443
  User git
StrictHostKeyChecking no
EOF
chown ec2-user $EC2_USER_HOME_FOLDER/.ssh/config
chgrp ec2-user $EC2_USER_HOME_FOLDER/.ssh/config
chmod 600 $EC2_USER_HOME_FOLDER/.ssh/config
#--TEMP CLONE A SINGLE BRANCH WHERE SECRETS HAVE BEEN CHANGED! - AW
su ec2-user bash -c "git clone --single-branch --branch feat-laa-ccms-soa-mp ssh://git@ssh.github.com:443/ministryofjustice/laa-ccms-app-soa.git $EFS_MOUNT_POINT/laa-ccms-app-soa || git -C $EFS_MOUNT_POINT/laa-ccms-app-soa pull"

#--Install s3fs and pre-reqs
yum install fuse -y
yum install fuse-libs -y
yum install s3fs-fuse -y

#--Make S3 integration dirs and mount S3
sudo sed -i '/^#.*user_allow_other/s/^#//' /etc/fuse.conf
mkdir -p $INBOUND_S3_MOUNT_POINT
mkdir -p $OUTBOUND_S3_MOUNT_POINT
chmod 777 $INBOUND_S3_MOUNT_POINT
chmod 777 $OUTBOUND_S3_MOUNT_POINT
s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${inbound_bucket} $INBOUND_S3_MOUNT_POINT
s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${outbound_bucket} $OUTBOUND_S3_MOUNT_POINT

#--Add S3 mounts to fstab (incase of reboot)
echo s3fs#${inbound_bucket} $EC2_USER_HOME_FOLDER/inbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab
echo s3fs#${outbound_bucket} $EC2_USER_HOME_FOLDER/outbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab

#--Create essential subdirs in S3
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

# clear all admin files and entries from config.xml on admin host only
reset_admin() {
  domain_home=$EFS_MOUNT_POINT/domains/soainfra
  config_location=$domain_home/config

  yum install -y xmlstarlet

  cp -p $config_location/config.xml $config_location/config.xml.$(date '+%Y%m%d-%H%M').bak
  cp -p $config_location/config.xml $config_location/config.xml.none

  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:server[./x:name[contains(text(),'ccms_soa_ms')]]" $config_location/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:machine[./x:name[contains(text(),'MACHINE-')]]" $config_location/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:migratable-target[./x:name[contains(text(),'ccms_soa_ms')]]" $config_location/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -u "//x:coherence-cluster-system-resource/x:target" -v "AdminServer" $config_location/config.xml.none

  cp -p $config_location/config.xml.none $config_location/config.xml

  rm -rf $domain_home/original
  rm -rf $domain_home/pending
  rm -rf $domain_home/edit
  rm -f $domain_home/edit.lok
  rm -rf $domain_home/servers/domain_bak
  rm -rf $domain_home/servers/AdminServer/cache
  rm -rf $domain_home/servers/AdminServer/logs
  rm -rf $domain_home/servers/AdminServer/tmp
}

if [[ "${server}" = "admin" ]]; then
  reset_admin
fi


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
su ec2-user bash -c "git clone ssh://git@ssh.github.com:443/ministryofjustice/laa-ccms-app-soa.git $EFS_MOUNT_POINT/laa-ccms-app-soa || git -C $EFS_MOUNT_POINT/laa-ccms-app-soa pull"

#--Populate custom monitoring files
su ec2-user bash -c "cp $EFS_MOUNT_POINT/laa-ccms-app-soa/monitoring/* $EFS_MOUNT_POINT/"

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
  DOMAIN_HOME=$EFS_MOUNT_POINT/domains/soainfra
  CONFIG_LOCATION=$DOMAIN_HOME/config

  cp -p $CONFIG_LOCATION/config.xml $CONFIG_LOCATION/config.xml.$(date '+%Y%m%d-%H%M').bak
  cp -p $CONFIG_LOCATION/config.xml $CONFIG_LOCATION/config.xml.none

  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:server[./x:name[contains(text(),'ccms_soa_ms')]]" $CONFIG_LOCATION/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:machine[./x:name[contains(text(),'MACHINE-')]]" $CONFIG_LOCATION/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:migratable-target[./x:name[contains(text(),'ccms_soa_ms')]]" $CONFIG_LOCATION/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -u "//x:coherence-cluster-system-resource/x:target" -v "AdminServer" $CONFIG_LOCATION/config.xml.none

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
  xmlstarlet ed \
    -u "/domain/server[name='AdminServer']/web-server/weblogic-plugin-enabled" -v "true" \
    -s "/domain/server[name='AdminServer']/web-server" -t elem -n "weblogic-plugin-enabled" -v "true" \
    $CONFIG_LOCATION/config.xml > $CONFIG_LOCATION/config.xml.new && mv $CONFIG_LOCATION/config.xml.new $CONFIG_LOCATION/config.xml
}

#--Deploy Cortex Agent (Also known as XDR Agent). SOC Monitoring
deploy_cortex() {
  CORTEX_DIR=/tmp/CortexAgent
  CORTEX_VERSION=linux_8_8_0_133595_rpm

  #--Prep
  mkdir -p $CORTEX_DIR/linux_8_8_0_133595_rpm
  mkdir /etc/panw
  aws s3 sync s3://ccms-shared/CortexAgent/ $CORTEX_DIR #--ccms-shared is in the EBS dev account 767123802783. Bucket is shared at the ORG LEVEL.
  tar zxf $CORTEX_DIR/$CORTEX_VERSION.tar.gz -C $CORTEX_DIR/$CORTEX_VERSION
  cp $CORTEX_DIR/$CORTEX_VERSION/cortex.conf /etc/panw/cortex.conf

  #--Installs
  yum install -y selinux-policy-devel
  rpm -Uvh $CORTEX_DIR/$CORTEX_VERSION/cortex-*.rpm
  systemctl status traps_pmd
  echo "Cortex Install Routine Complete. Installation Is NOT GUARANTEED -- Check Logs For Success"
}

if [[ "${server}" = "admin" ]]; then
  yum install -y xmlstarlet
  ensure_https
  reset_admin
fi

if [[ "${deploy_environment}" = "production" ]]; then
  deploy_cortex
fi

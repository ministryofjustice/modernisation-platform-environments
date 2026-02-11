#!/bin/bash

set -euxo pipefail
exec > /var/log/user-data.log 2>&1

EC2_USER_HOME_FOLDER=/home/ec2-user
EFS_MOUNT_POINT=$EC2_USER_HOME_FOLDER/efs

# #--Variables for AWS Secrets Manager
# SECRET_NAME="soasandbox-password"
# SECRET_KEY="ccms/soasandbox/deploy-github-ssh-key"
# REGION="eu-west-2"

echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config
echo 'ECS_INSTANCE_ATTRIBUTES={"server": "${server}","latest": "true"}' >> /etc/ecs/ecs.config


#--Configure EFS
yum install -y amazon-efs-utils
mkdir -p $EFS_MOUNT_POINT
mount -t efs -o tls ${efs_id}:/ $EFS_MOUNT_POINT

# verify EFS is mounted successfully or not
mountpoint -q $EFS_MOUNT_POINT || (echo "EFS mount failed" && exit 1)

#--Set permissions for EFS mount point
chown ec2-user:ec2-user $EFS_MOUNT_POINT
chmod 755 $EFS_MOUNT_POINT
# chmod go+rw $EFS_MOUNT_POINT

# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=$EFS_MOUNT_POINT/large_file_for_efs_performance bs=1024k count=10000

#--Add EPEL Repo
amazon-linux-extras install epel -y

#--Install AWSCLI & jq for JSON parsing in bash
yum install -y awscli
yum install -y jq

# Configure SSH and pull git repo
mkdir -p /home/ec2-user/.ssh
chown ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh

yum install git -y
su ec2-user bash -c "aws secretsmanager get-secret-value --secret-id soasandbox-password --region eu-west-2 --query SecretString --output text | jq -r --arg key \"ccms/soasandbox/deploy-github-ssh-key\" '.[\$key]' > /home/ec2-user/.ssh/id_rsa"

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

if [[ "${server}" = "admin" ]]; then
  yum install -y xmlstarlet
  ensure_https
  reset_admin
fi
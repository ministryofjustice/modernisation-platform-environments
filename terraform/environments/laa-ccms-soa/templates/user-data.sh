#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config
echo 'ECS_INSTANCE_ATTRIBUTES={"server": "${server}","latest": "true"}' >> /etc/ecs/ecs.config

#--Configure EFS
yum install -y amazon-efs-utils
mkdir /home/ec2-user/efs
mount -t efs -o tls ${efs_id}:/ /home/ec2-user/efs
chmod go+rw /home/ec2-user/efs
# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=/home/ec2-user/efs/large_file_for_efs_performance bs=1024k count=10000

#--Add EPEL Repo
amazon-linux-extras install epel -y

#--Install AWSCLI
yum install -y awscli

# Configure SSH and pull git repo
yum install git -y
aws secretsmanager get-secret-value --secret-id ccms/soa/deploy-github-ssh-key --query SecretString --output text | base64 -d > /home/ec2-user/.ssh/id_rsa
chown ec2-user /home/ec2-user/.ssh/id_rsa
chgrp ec2-user /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa
cat <<EOF > /home/ec2-user/.ssh/config
host ssh.github.com
  HostName ssh.github.com
  Port 443
  User git
StrictHostKeyChecking no
EOF
chown ec2-user /home/ec2-user/.ssh/config
chgrp ec2-user /home/ec2-user/.ssh/config
chmod 600 /home/ec2-user/.ssh/config
#--TEMP CLONE A SINGLE BRANCH WHERE SECRETS HAVE BEEN CHANGED! - AW
su ec2-user bash -c "git clone --single-branch --branch feat-laa-ccms-soa-mp ssh://git@ssh.github.com:443/ministryofjustice/laa-ccms-app-soa.git /home/ec2-user/efs/laa-ccms-app-soa || git -C /home/ec2-user/efs/laa-ccms-app-soa pull"

#--Install s3fs and pre-reqs
yum install fuse -y
yum install fuse-libs -y
yum install s3fs-fuse -y

#--Make S3 integration dirs and mount S3
sudo sed -i '/^#.*user_allow_other/s/^#//' /etc/fuse.conf
mkdir /home/ec2-user/inbound
mkdir /home/ec2-user/outbound
chmod 777 /home/ec2-user/inbound
chmod 777 /home/ec2-user/outbound
s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${inbound_bucket} /home/ec2-user/inbound
s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${outbound_bucket} /home/ec2-user/outbound

#--Add S3 mounts to fstab (incase of reboot)
echo s3fs#${inbound_bucket} /home/ec2-user/inbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab
echo s3fs#${outbound_bucket} /home/ec2-user/outbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab

# clear all admin files and entries from config.xml on admin host only
reset_admin() {
  domain_home=/home/ec2-user/efs/domains/soainfra
  config_location=$domain_home/config
  curl http://fr2.rpmfind.net/linux/dag/redhat/el6/en/i386/dag/RPMS/xmlstarlet-1.5.0-1.el6.rf.i686.rpm --output xmlstarlet-1.5.0-1.el6.rf.i686.rpm
  yum install -y xmlstarlet-1.5.0-1.el6.rf.i686.rpm

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

if [[ -d /home/ec2-user/efs/domains/soainfra ]] && [[ "${server}" = "admin" ]]; then
  reset_admin
fi
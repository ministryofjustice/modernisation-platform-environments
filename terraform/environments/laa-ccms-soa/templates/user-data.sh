#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config
echo 'ECS_INSTANCE_ATTRIBUTES={"server": "${server}","latest": "true"}' >> /etc/ecs/ecs.config

# configure efs
yum install -y amazon-efs-utils
mkdir /home/ec2-user/efs
mount -t efs -o tls ${efs_id}:/ /home/ec2-user/efs
chmod go+rw /home/ec2-user/efs
# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=/home/ec2-user/efs/large_file_for_efs_performance bs=1024k count=10000

# clear all admin files and entries from config.xml
reset_admin() {
  domain_home=/home/ec2-user/efs/domains/soainfra
  config_location=$domain_home/config
  curl http://fr2.rpmfind.net/linux/dag/redhat/el6/en/i386/dag/RPMS/xmlstarlet-1.5.0-1.el6.rf.i686.rpm --output xmlstarlet-1.5.0-1.el6.rf.i686.rpm
  yum install -y xmlstarlet-1.5.0-1.el6.rf.i686.rpm

  sudo cp -p $config_location/config.xml $config_location/config.xml.$(date '+%Y%m%d-%H%M').bak
  sudo cp -p $config_location/config.xml $config_location/config.xml.none

  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:server[./x:name[contains(text(),'ccms_soa_ms')]]" $config_location/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:machine[./x:name[contains(text(),'MACHINE-')]]" $config_location/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -d "//x:migratable-target[./x:name[contains(text(),'ccms_soa_ms')]]" $config_location/config.xml.none
  xmlstarlet ed --inplace -N x="http://xmlns.oracle.com/weblogic/domain" -u "//x:coherence-cluster-system-resource/x:target" -v "AdminServer" $config_location/config.xml.none

  sudo cp -p $config_location/config.xml.none $config_location/config.xml

  sudo rm -rf $domain_home/original
  sudo rm -rf $domain_home/pending
  sudo rm -rf $domain_home/edit
  sudo rm -f $domain_home/edit.lok
  sudo rm -rf $domain_home/servers/domain_bak
  sudo rm -rf $domain_home/servers/AdminServer/cache
  sudo rm -rf $domain_home/servers/AdminServer/logs
  sudo rm -rf $domain_home/servers/AdminServer/tmp
}

if [ "${server}" = "admin" ]; then
  reset_admin
fi

service start ecs

# # install aws cli
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# sudo yum install unzip -y
# unzip awscliv2.zip
# sudo ./aws/install
# rm -rf aws
# rm awscliv2.zip

# install git and pull repo
sudo yum install git -y
aws secretsmanager get-secret-value --secret-id ccms/soa/deploy-github-ssh-key --query SecretString --output text | base64 -d > /home/ec2-user/.ssh/laa-ccms-app-soa.pem
chown ec2-user /home/ec2-user/.ssh/laa-ccms-app-soa.pem
chgrp ec2-user /home/ec2-user/.ssh/laa-ccms-app-soa.pem
chmod 400 /home/ec2-user/.ssh/laa-ccms-app-soa.pem
cat <<EOF > /home/ec2-user/.ssh/config
host github.com
 HostName github.com
 IdentityFile /home/ec2-user/.ssh/laa-ccms-app-soa.pem
 User git
StrictHostKeyChecking no
EOF
chown ec2-user /home/ec2-user/.ssh/config
chgrp ec2-user /home/ec2-user/.ssh/config
chmod 600 /home/ec2-user/.ssh/config
#--TEMP CLONE A SINGLE BRANCH WHERE SECRETS HAVE BEEN CHANGED! - AW
su ec2-user bash -c "git clone --single-branch --branch feat-laa-ccms-soa-mp git@github.com:ministryofjustice/laa-ccms-app-soa.git /home/ec2-user/efs/laa-ccms-app-soa || git -C /home/ec2-user/efs/laa-ccms-app-soa pull"

# install git-crypt and decrypt repo
yum -y install gcc-c++ openssl-devel
curl -L "https://github.com/AGWA/git-crypt/archive/0.6.0.tar.gz" | tar zxv -C /var/tmp
cd "/var/tmp/git-crypt-0.6.0"
make
make install PREFIX=/usr/local
rm -r "/var/tmp/git-crypt-0.6.0"
yum remove gcc-c++ openssl-devel -y
yum clean packages
aws secretsmanager get-secret-value --secret-id ccms/soa/deploy-gitcrypt-gpg-key --query SecretString --output text | base64 -d > /home/ec2-user/.ssh/laa-ccms-gpg-private.key
chown ec2-user /home/ec2-user/.ssh/laa-ccms-gpg-private.key
chgrp ec2-user /home/ec2-user/.ssh/laa-ccms-gpg-private.key
chmod 400 /home/ec2-user/.ssh/laa-ccms-gpg-private.key
su ec2-user bash -c "gpg --import /home/ec2-user/.ssh/laa-ccms-gpg-private.key"
cd /home/ec2-user/efs/laa-ccms-app-soa
su ec2-user bash -c "git-crypt unlock"

# Install s3fs
sudo yum install fuse -y
sudo yum install fuse-libs -y
sudo amazon-linux-extras install epel -y
sudo yum install s3fs-fuse -y

cd /etc

#--TEMP DISABLED - FTP IS BEING REBUILT AS PART OF LZ MIGRATION - AW
#sudo cat > mount_s3.sh << EOF
#!/bin/bash

#s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${inbound_bucket} /home/ec2-user/inbound
#s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${outbound_bucket} /home/ec2-user/outbound
#EOF
#
#chmod 755 /etc/mount_s3.sh
#echo ./mount_s3.sh >> /etc/rc.local
#
#
#mkdir /home/ec2-user/inbound
#mkdir /home/ec2-user/outbound
#chmod 777 /home/ec2-user/inbound
#chmod 777 /home/ec2-user/outbound
#
#./mount_s3.sh
#
#echo s3fs#${inbound_bucket} /home/ec2-user/inbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab
#echo s3fs#${outbound_bucket} /home/ec2-user/outbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab

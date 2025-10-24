#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config

start ecs

yum install -y amazon-efs-utils
mkdir /home/ec2-user/efs
mount -t efs -o tls ${efs_id}:/ /home/ec2-user/efs
chmod go+rw /home/ec2-user/efs

yum install -y awscli

deploy_cortex() {
  CORTEX_DIR=/tmp/CortexAgent
  CORTEX_VERSION=linux_8_8_0_133595_rpm

  #--Prep
  mkdir -p $CORTEX_DIR/linux_8_8_0_133595_rpm
  mkdir /etc/panw
  aws s3 sync s3://ccms-shared/CortexAgent/ $CORTEX_DIR #--ccms-shared is in the EBS dev account 767123802783. Bucket is shared at the ORG LEVEL.
  tar zxf $CORTEX_DIR/$CORTEX_VERSION.tar.gz -C $CORTEX_DIR/$CORTEX_VERSION
  cp $CORTEX_DIR/$CORTEX_VERSION/cortex.conf /etc/panw/cortex.conf
  sed -i -e '$a\' /etc/panw/cortex.conf && echo "--endpoint-tags ccms,oia" >> /etc/panw/cortex.conf

  #--Installs
  yum install -y selinux-policy-devel
  rpm -Uvh $CORTEX_DIR/$CORTEX_VERSION/cortex-*.rpm
  systemctl status traps_pmd
  echo "Cortex Install Routine Complete. Installation Is NOT GUARANTEED -- Check Logs For Success"
}

if [[ "${deploy_environment}" = "production" ]]; then
  deploy_cortex
fi
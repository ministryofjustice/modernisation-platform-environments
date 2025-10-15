#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config

start ecs

yum install -y amazon-efs-utils
mkdir /home/ec2-user/efs
mount -t efs -o tls ${efs_id}:/ /home/ec2-user/efs
chmod go+rw /home/ec2-user/efs

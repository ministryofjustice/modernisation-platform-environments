#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo 'ECS_ENABLE_CONTAINER_METADATA=true' >> /etc/ecs/ecs.config
echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config
echo 'ECS_INSTANCE_ATTRIBUTES={"server": "${server}"}' >> /etc/ecs/ecs.config

yum install -y amazon-efs-utils
mkdir -p /home/ec2-user/efs
mount -t efs -o tls ${efs_id}:/ /home/ec2-user/efs
chmod go+rw /home/ec2-user/efs

#--Mount the ccms-ebs inbound/outbound S3 buckets for SOA file-based integration
#--AL2023 has no s3fs-fuse package, so use Mountpoint for S3 (as laa-ccms-soa does)
sed -i '/^#.*user_allow_other/s/^#//' /etc/fuse.conf
dnf install -y mount-s3

mkdir -p /home/ec2-user/inbound
mkdir -p /home/ec2-user/outbound
chmod 777 /home/ec2-user/inbound
chmod 777 /home/ec2-user/outbound
chown -R 1000:1000 /home/ec2-user/inbound
chown -R 1000:1000 /home/ec2-user/outbound

mount-s3 ${inbound_bucket} /home/ec2-user/inbound --allow-other --uid 1000 --gid 1000 --dir-mode 0777 --file-mode 0777
mount-s3 ${outbound_bucket} /home/ec2-user/outbound --allow-other --uid 1000 --gid 1000 --dir-mode 0777 --file-mode 0777

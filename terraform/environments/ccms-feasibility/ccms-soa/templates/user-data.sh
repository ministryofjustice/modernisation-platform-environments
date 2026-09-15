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
yum install -y s3fs-fuse

mkdir -p /home/ec2-user/inbound
mkdir -p /home/ec2-user/outbound
chmod 777 /home/ec2-user/inbound
chmod 777 /home/ec2-user/outbound

s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${inbound_bucket} /home/ec2-user/inbound
s3fs -o iam_role=auto -o url="https://s3-eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o allow_other -o multireq_max=5 -o use_cache=/tmp -o uid=1000 -o gid=1000 ${outbound_bucket} /home/ec2-user/outbound

echo s3fs#${inbound_bucket} /home/ec2-user/inbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab
echo s3fs#${outbound_bucket} /home/ec2-user/outbound fuse iam_role=auto,url="https://s3-eu-west-2.amazonaws.com",endpoint=eu-west-2,allow_other,multireq_max=5,use_cache=/tmp,uid=1000,gid=1000 0 0 >> /etc/fstab

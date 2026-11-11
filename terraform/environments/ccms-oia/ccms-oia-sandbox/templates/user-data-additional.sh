#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
# echo 'ECS_VOLUME_PLUGIN_CAPABILITIES=["efsAuth"]' >> /etc/ecs/ecs.config

start ecs

yum install -y awscli
dnf update -y ca-certificates --releasever 2023.12.20261026
update-ca-trust

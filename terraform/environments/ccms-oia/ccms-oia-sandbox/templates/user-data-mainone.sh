#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config

start ecs
yum install -y awscli
yum update ca-certificates
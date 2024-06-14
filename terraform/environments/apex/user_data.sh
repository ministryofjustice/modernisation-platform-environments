#!/bin/bash -xe
echo ECS_CLUSTER=${app_name} >> /etc/ecs/ecs.config
echo ECS_IMAGE_PULL_BEHAVIOR=always >> /etc/ecs/ecs.config
yum install -y aws-cfn-bootstrap awslogs
cat >/etc/awslogs/awslogs.conf <<-EOF
[general]
state_file = /var/lib/awslogs/agent-state
[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
buffer_duration = 5000
log_stream_name = secure/{instance_id}
initial_position = start_of_file
log_group_name = ${app_name}-ecs-ec2-logs
[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = messages/{instance_id}
initial_position = start_of_file
log_group_name = ${app_name}-ecs-ec2-logs
[/var/log/ecs/ecs-init.log]
datetime_format = %Y-%m-%dT%H:%M:%SZ
file = /var/log/ecs/ecs-init.log
buffer_duration = 5000
initial_position = start_of_file
log_stream_name = ecs-init/{instance_id}
log_group_name = ${app_name}-ecs-ec2-logs
[/var/log/ecs/ecs-agent.log]
datetime_format = %Y-%m-%dT%H:%M:%SZ
file = /var/log/ecs/ecs-agent.log.*
buffer_duration = 5000
initial_position = start_of_file
log_stream_name = ecs-agent/{instance_id}
log_group_name = ${app_name}-ecs-ec2-logs
EOF
chmod 644 /etc/awslogs/awslogs.conf
# Change region
sed -i 's/^region = .*/region = eu-west-2/g' /etc/awslogs/awscli.conf
sudo systemctl start awslogsd
sudo systemctl enable awslogsd.service
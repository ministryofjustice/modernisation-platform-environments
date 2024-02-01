#!/bin/bash -xe
echo ECS_CLUSTER=${app_ecs_cluster} >> /etc/ecs/ecs.config
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
log_group_name = ${app_name}-EC2

[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = messages/{instance_id}
initial_position = start_of_file
log_group_name = ${app_name}-EC2
EOF
chmod 644 /etc/awslogs/awslogs.conf
# Change region
sed -i 's/^region = .*/region = eu-west-2/g' /etc/awslogs/awscli.conf
chkconfig awslogs on
service awslogs restart
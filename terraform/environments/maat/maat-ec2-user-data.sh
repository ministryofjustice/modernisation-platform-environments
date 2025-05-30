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
log_group_name = ${maat_ec2_log_group}

[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = messages/{instance_id}
initial_position = start_of_file
log_group_name = ${maat_ec2_log_group}
EOF
chmod 644 /etc/awslogs/awslogs.conf
# Change region
sed -i 's/^region = .*/region = eu-west-2/g' /etc/awslogs/awscli.conf
sudo systemctl start awslogsd
sudo systemctl enable awslogsd.service

# Install XDC agent stored in S3 bucket
aws s3 cp s3://${xdr_bucket}/cortex.rpm /tmp/cortex.rpm

if [[ -f /tmp/cortex.rpm ]]; then
    yum install -y /tmp/cortex.rpm
else
    echo "XDR agent download failed" >&2
    exit 1
fi

#!/bin/bash -xe
echo ECS_CLUSTER=${app_name} >> /etc/ecs/ecs.config
echo ECS_IMAGE_PULL_BEHAVIOR=always >> /etc/ecs/ecs.config
yum install -y awslogs
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
[/var/log/ecs/ecs-init.log]
datetime_format = %Y-%m-%dT%H:%M:%SZ
file = /var/log/ecs/ecs-init.log
buffer_duration = 5000
initial_position = start_of_file
log_stream_name = ecs-init/{instance_id}
log_group_name = ${app_name}-EC2
[/var/log/ecs/ecs-agent.log]
datetime_format = %Y-%m-%dT%H:%M:%SZ
file = /var/log/ecs/ecs-agent.log.*
buffer_duration = 5000
initial_position = start_of_file
log_stream_name = ecs-agent/{instance_id}
log_group_name = ${app_name}-EC2
EOF
chmod 644 /etc/awslogs/awslogs.conf
# Change region
sed -i 's/^region = .*/region = eu-west-2/g' /etc/awslogs/awscli.conf
sudo systemctl start awslogsd
sudo systemctl enable awslogsd.service
systemctl enable docker

# Cloudwatch Agent
amazon-linux-extras install collectd
yum install -y amazon-cloudwatch-agent
aws s3 cp s3://modernisation-platform-software20230224000709766100000001/laa-platform/cloudwatch-agent-config/config.json /opt/aws/amazon-cloudwatch-agent/bin/.
if [[ -f /opt/aws/amazon-cloudwatch-agent/bin/config.json ]]; then
  amazon-cloudwatch-agent-ctl -a stop
  amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
fi

# Install XDR agent stored in S3 bucket
XDR_AGENT_BUCKET="s3://modernisation-platform-laa-shared20250605080758955300000001/laa-platform/xdr-agent/"
if [[ "production" = "${environment}" ]]; then
  AGENT_PATH="prod/cortex-agent.tar.gz"
else
  AGENT_PATH="pre-prod/cortex-agent.tar.gz"
fi

aws s3 cp "$${XDR_AGENT_BUCKET}$${AGENT_PATH}" ${xdr_tar}

if [[ -f ${xdr_tar} ]]; then
  mkdir -p ${xdr_dir}
  tar -xzf ${xdr_tar} -C ${xdr_dir}

  if [[ -f ${xdr_dir}/cortex.conf ]]; then
    sudo mkdir -p /etc/panw
    sudo cp ${xdr_dir}/cortex.conf /etc/panw/
  else
    echo "Missing cortex.conf in extracted archive" >&2
    exit 1
  fi

  sudo yum install -y ${xdr_dir}/*.rpm
  sudo /opt/traps/bin/cytool endpoint_tags add "${xdr_tags}"

else
  echo "XDR agent download failed" >&2
  exit 1
fi

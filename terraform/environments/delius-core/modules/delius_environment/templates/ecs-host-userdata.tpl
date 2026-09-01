#!/bin/bash
set -x
# Install additional packages
sudo yum install -y amazon-efs-utils nfs-utils jq amazon-cloudwatch-agent unzip

# Install and start SSM Agent service - will always want the latest - used for remote access via aws console/cli
# Avoids need to manage users identity in 2 places and install ansible/dependencies
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Set any ECS agent configuration options
echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config
# Block tasks running in awsvpc mode from calling host metadata
echo "ECS_AWSVPC_BLOCK_IMDS=true" >> /etc/ecs/ecs.config
# Required for ecs tasks in awsvpc mode to pull images remotely
echo "ECS_ENABLE_TASK_ENI=true" >> /etc/ecs/ecs.config

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "agent": {
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "CWAgent",
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s


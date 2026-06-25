#!/bin/bash -xe
echo ECS_CLUSTER=${app_ecs_cluster} >> /etc/ecs/ecs.config
# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent
# Write CloudWatch Agent config (provided via Terraform)
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<-EOF
${cw_agent_config}
EOF

chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start rsyslog
sudo yum install -y rsyslog
sudo systemctl enable rsyslog
sudo systemctl start rsyslog

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent


# Install prerequisites for Cortex agent
sudo yum install -y selinux-policy-devel

# Install XDR agent stored in S3 bucket
XDR_AGENT_BUCKET="s3://modernisation-platform-laa-shared20250605080758955300000001/laa-platform/xdr-agent/"
if [[ "production" = "${environment}" ]]; then
  AGENT_PATH="prod/cortex-agent.tar.gz"
else
  AGENT_PATH="pre-prod/cortex-agent.tar.gz"
fi

aws s3 cp "$${XDR_AGENT_BUCKET}$${AGENT_PATH}" "${xdr_tar}"

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


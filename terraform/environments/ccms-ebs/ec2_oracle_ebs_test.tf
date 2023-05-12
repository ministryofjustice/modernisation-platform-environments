#  Build EC2 
resource "aws_instance" "ec2_oracle_ebs2" {
  instance_type = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsdb
  #ami                         = data.aws_ami.oracle_db.id
  ami                         = data.aws_ami.accessgate.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebsdb.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsdb
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsdb

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  #lifecycle {
  #  ignore_changes = [ebs_block_device]
  #}
  lifecycle {
    ignore_changes = [user_data_replace_on_change,user_data]
  }
  user_data_replace_on_change = false
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel

# AWS CW Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

# AWS SSM Agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

# s3Fuse
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse/
./autogen.sh
./configure
make
make install
cd /
mkdir /rman
s3fs -o iam_role="role_stsassume_oracle_base" -o url="https://s3.eu-west-2.amazonaws.com" -o endpoint=eu-west-2 -o dbglevel=info -o curldbg -o allow_other -o use_cache=/tmp ccms-ebs-development-dbbackup /rman
echo "ccms-ebs-development-dbbackup /rman fuse.s3fs _netdev,allow_other,url=https://s3.eu-west-2.amazonaws.com,iam_role=role_stsassume_oracle_base 0 0" >> /etc/fstab

EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags,
    { Name = "testbox"},
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebsdb]
}

## playground box using webgate AMI and SG

resource "aws_instance" "ec2_testbox" {
  count                       = local.application_data.accounts[local.environment].webgate_no_instances
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_webgate
  ami                         = data.aws_ami.webgate.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_webgate.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  lifecycle {
    ignore_changes = [ebs_block_device]
  }
  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent
mount -a

EOF



  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-testbox-%s", local.application_name, local.environment, count.index + 1)) }
  )
}
/*
module "cw-testbox-ec2" {
  source = "./modules/cw-ec2"

  name        = "ec2-testbox"
  topic       = aws_sns_topic.cw_alerts.arn
  instanceIds = join(",", [for instance in aws_instance.ec2_testbox : instance.id])

  for_each     = local.application_data.cloudwatch_ec2
  metric       = each.key
  eval_periods = each.value.eval_periods
  period       = each.value.period
  threshold    = each.value.threshold
}
*/
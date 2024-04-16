locals {
  instance-userdata = <<EOF
#!/bin/bash
cd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
echo "${aws_efs_file_system.efs.dns_name}:/ /backups nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport" >> /etc/fstab
mount -a

cd /etc
mkdir cloudwatch_agent
cd cloudwatch_agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
echo '${data.local_file.cloudwatch_agent.content}' > cloudwatch_agent_config.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/cloudwatch_agent/cloudwatch_agent_config.json

EOF
}




resource "aws_instance" "delete-account_test_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.id
  user_data_base64            = base64encode(local.instance-userdata)


  root_block_device {
    delete_on_termination = false
    encrypted             = true
    volume_size           = 60
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}test-ec2-root" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} test server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}
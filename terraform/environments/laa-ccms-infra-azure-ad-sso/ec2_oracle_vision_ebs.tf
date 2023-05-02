# Build EC2 for EBS Vision
resource "aws_instance" "ec2_oracle_vision_ebs" {
  instance_type = local.application_data.accounts[local.environment].ec2_oracle_vision_instance_type_ebsdb
  ami           = data.aws_ami.oracle_ebs_vision_db.id
  #subnet_id                  = data.aws_subnet.data_subnets_a.id
  subnet_id                   = local.environment == "development" ? data.aws_subnet.data_subnets_a.id : data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instance_profile_ebs_vision.name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebs_vision_db.id]


  user_data_replace_on_change = false
  user_data                   = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
yum update -y
yum install -y wget unzip
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

systemctl stop amazon-ssm-agent
systemctl start amazon-ssm-agent

EOF
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-vision", local.application_name, local.environment)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebs_vision_db]
}





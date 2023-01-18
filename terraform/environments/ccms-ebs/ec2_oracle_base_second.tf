data "aws_ami" "oracle_base_second" {
  most_recent = true
  #owners      = ["131827586825"]
  #owners = ["amazon"]
  owners = ["self"]
  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_ami_name_second]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#  Build EC2 
resource "aws_instance" "ec2_oracle_base_second" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_base_instance_type
  ami                         = data.aws_ami.oracle_base_second.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  #iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base_2.name
  iam_instance_profile = aws_iam_instance_profile.iam_instace_profile_oracle_base.name
  # explicitly adding namespace server due to oracle linux not having the servers
  user_data = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
echo date
sudo yum update -y
sudo yum install -y telnet
echo "nameserver 10.26.56.2" | sudo tee /etc/resolv.conf -a
sudo touch /etc/dhcp/dhclient.conf
echo "supersede domain-name-servers 10.26.56.2;" | sudo tee /etc/dhcp/dhclient.conf -a
#sudo systemctl reload NetworkManager
sudo systemctl restart amazon-ssm-agent
echo date

EOF


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-OracleBase-second", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_oracle_base]
}

/*
resource "aws_iam_role" "role_stsassume_oracle_base_2" {
  name                 = "role_stsassume_oracle_base_2"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = merge(local.tags,
    { Name = lower(format("RoleSsm-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_policy_oracle_base_2" {
  role       = aws_iam_role.role_stsassume_oracle_base_2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "iam_instace_profile_oracle_base_2" {
  name = "iam_instace_profile_oracle_base_2"
  role = aws_iam_role.role_stsassume_oracle_base_2.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("IamProfile-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_logging_oracle_base_2" {
  role       = aws_iam_role.role_stsassume_oracle_base_2.name
  policy_arn = aws_iam_policy.oracle_ec2_ssm_policy.arn
}
*/
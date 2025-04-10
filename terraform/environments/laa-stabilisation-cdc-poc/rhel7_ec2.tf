locals {
  # EC2 User data
  rhel7_userdata = <<EOF
#!/bin/bash

# Setting up SSM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
EOF

}

#################################
# rhel7 Security Group Rules
#################################

resource "aws_security_group" "rhel7_instance" {
  name        = "rhel7-${local.environment}-rhel7-security-group"
  description = "Security group for RHEL 7 EC2 for CWA POC"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "rhel7-${local.environment}-rhel7-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "rhel7_outbound" {
  security_group_id = aws_security_group.rhel7_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


######################################
# rhel7 Instance
######################################

resource "aws_instance" "rhel7_instance_1" {
  ami                         = local.application_data.accounts[local.environment].rhel7_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].rhel7_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.rhel7_instance.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.cwa.id
  user_data_base64            = base64encode(local.rhel7_userdata)
  user_data_replace_on_change = false

  root_block_device {
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      local.tags,
      { "Name" = "rhel7-instance-root" }
    )
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "rhel7 Instance 1" }
  )
}

###############################
# rhel7 EBS Volumes
###############################

resource "aws_ebs_volume" "rhel7_volume1" {
  availability_zone = "eu-west-2a"
  size              = "50"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "rhel7-volume1" },
  )
}

resource "aws_volume_attachment" "rhel7_volume1" {
  device_name = "/dev/xvdk"
  volume_id   = aws_ebs_volume.rhel7_volume1.id
  instance_id = aws_instance.rhel7_instance_1.id
}

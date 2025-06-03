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
  name        = "${local.application_name_short}-rhel7-${local.environment}-security-group"
  description = "Security group for RHEL 7 EC2 for Portal POC"
  vpc_id      = var.shared_vpc_id

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-rhel7-${local.environment}-rhel7-security-group" }
  )

}

resource "aws_vpc_security_group_ingress_rule" "rhel7_workspace_ssh" {
  security_group_id = aws_security_group.rhel7_instance.id
  description       = "SSH access from LZ Workspace"
  cidr_ipv4         = local.management_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "rhel7_portal_poc_1" {
  security_group_id            = aws_security_group.rhel7_instance.id
  description                  = "SSH access from Portal POC App1"
  referenced_security_group_id = aws_security_group.cwa_poc2_app.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "rhel7_bastion_ssh" {
  security_group_id            = aws_security_group.rhel7_instance.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = var.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "rhel7_workspace_ohs_http" {
  security_group_id = aws_security_group.rhel7_instance.id
  description       = "Allow (OHS HTTP) from WorkSpace access"
  cidr_ipv4         = local.management_cidr
  from_port         = 7777
  ip_protocol       = "tcp"
  to_port           = 7777
}

resource "aws_vpc_security_group_ingress_rule" "rhel7_workspace_ohs_https" {
  security_group_id = aws_security_group.rhel7_instance.id
  description       = "Allow (OHS HTTPS) from WorkSpace access"
  cidr_ipv4         = local.management_cidr
  from_port         = 4443
  ip_protocol       = "tcp"
  to_port           = 4443
}

resource "aws_vpc_security_group_ingress_rule" "rhel7_workspace_weblogic" {
  security_group_id = aws_security_group.rhel7_instance.id
  description       = "Allow (Weblogic) from WorkSpace access"
  cidr_ipv4         = local.management_cidr
  from_port         = 7001
  ip_protocol       = "tcp"
  to_port           = 7001
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
  ami                         = var.application_data.accounts[local.environment].rhel7_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = var.application_data.accounts[local.environment].rhel7_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.rhel7_instance.id]
  subnet_id                   = var.data_subnet_a_id
  iam_instance_profile        = aws_iam_instance_profile.rhel7.id
  user_data_base64            = base64encode(local.rhel7_userdata)
  user_data_replace_on_change = false

  root_block_device {
    encrypted  = true
    kms_key_id = var.shared_ebs_kms_key_id
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      var.tags,
      { "Name" = "${local.application_name_short}-rhel7-instance-root" }
    )
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    var.tags,
    { "Name" = "${local.application_name_short} rhel7 Instance 1" }
  )

  lifecycle {
    ignore_changes = [
      root_block_device[0].kms_key_id
    ]
  }

}

###############################
# rhel7 EBS Volumes
###############################

resource "aws_ebs_volume" "rhel7_volume1" {
  availability_zone = "eu-west-2a"
  size              = "50"
  type              = "gp2"
  encrypted         = true
  kms_key_id        = var.shared_ebs_kms_key_id

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    var.tags,
    { "Name" = "${local.application_name_short}-rhel7-volume1" },
  )
}

resource "aws_volume_attachment" "rhel7_volume1" {
  device_name = "/dev/xvdk"
  volume_id   = aws_ebs_volume.rhel7_volume1.id
  instance_id = aws_instance.rhel7_instance_1.id
}

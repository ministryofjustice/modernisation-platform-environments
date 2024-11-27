######################################
# CIS EC2 Instance
######################################

resource "aws_instance" "cis_db_instance" {
  ami                         = local.application_data.accounts[local.environment].app_ami_id
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  key_name                    = aws_key_pair.cis.key_name
  ebs_optimized               = true
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_instance_sg.id]
  user_data_base64            = base64encode(local.database-instance-userdata)
  user_data_replace_on_change = true

  root_block_device {
    delete_on_termination = false
    encrypted             = true
    volume_size           = 200
    volume_type           = "gp2"
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      local.tags,
      { "Name" = "${local.application_name_short}-root" }
    )
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short} Database Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}


######################################
# CIS IAM Role
######################################

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name_short}-ec2-profile"
  role = aws_iam_role.cis_ec2_role.name
}


######################################
# CIS EC2 EBS Volumes
######################################

resource "aws_ebs_volume" "ec2_ebs_sdf" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].sdfsize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].ebs_sdf_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-/dev/sdf" },
  )
}

resource "aws_volume_attachment" "ec2_ebs_sdf_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ec2_ebs_sdf.id
  instance_id = aws_instance.cis_db_instance.id
}


resource "aws_ebs_volume" "ec2_ebs_sdg" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].sdgsize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].ebs_sdg_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-/dev/sdg" },
  )
}

resource "aws_volume_attachment" "ec2_ebs_sdg_attachment" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.ec2_ebs_sdg.id
  instance_id = aws_instance.cis_db_instance.id
}


resource "aws_ebs_volume" "ec2_ebs_sdh" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].sdhsize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].ebs_sdh_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-/dev/sdh" },
  )
}

resource "aws_volume_attachment" "ec2_ebs_sdh_attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ec2_ebs_sdh.id
  instance_id = aws_instance.cis_db_instance.id
}


resource "aws_ebs_volume" "ec2_ebs_sdi" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].sdisize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].ebs_sdi_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-/dev/sdi" },
  )
}

resource "aws_volume_attachment" "ec2_ebs_sdi_attachment" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.ec2_ebs_sdi.id
  instance_id = aws_instance.cis_db_instance.id
}

######################################
# CIS EC2 Security Group
######################################

resource "aws_security_group" "ec2_instance_sg" {
  name        = "${local.application_name_short}-${local.environment}-app-security-group"
  description = "Security Group for EC2 DB instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-${local.environment}-app-security-group" }
  )
}

resource "aws_security_group_rule" "app_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_instance_sg.id
}

resource "aws_security_group_rule" "app_bastion_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_instance_sg.id
  source_security_group_id = module.bastion_linux.bastion_security_group
  description              = "SSH from the Bastion"
}

resource "aws_security_group_rule" "rds_workspaces" {
  type              = "ingress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_instance_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "RDS Workspace access"
}

resource "aws_security_group_rule" "dkron_workspaces" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_instance_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "Dkron Workspace access"
}

resource "aws_security_group_rule" "rds_test_env" {
  type              = "ingress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_instance_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].testenvcidr]
  description       = "RDS Workspace access"
}

resource "aws_security_group_rule" "ssh_workspaces" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_instance_sg.id
  cidr_blocks       = [local.application_data.accounts[local.environment].managementcidr]
  description       = "SSH Workspace access"
}
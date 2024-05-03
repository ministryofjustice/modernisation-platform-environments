locals {
  db_userdata = <<EOF
#!/bin/bash

EOF

}

######################################
# Database Instance
######################################

resource "aws_instance" "database" {
  ami                         = local.application_data.accounts[local.environment].db_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].db_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.database.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.cwa.id
  key_name                    = aws_key_pair.cwa.key_name
#   user_data_base64            = base64encode(local.db_userdata)
#   user_data_replace_on_change = true

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name} Database Instance" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_key_pair" "cwa" {
  key_name   = "${local.application_name_short}-ssh-key"
  public_key = local.application_data.accounts[local.environment].cwa_ec2_key
}

#################################
# Database Security Group Rules
#################################

resource "aws_security_group" "database" {
  name        = "${local.application_name}-${local.environment}-db-security-group"
  description = "Security Group for database"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-db-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "db_outbound" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.database.id
  description       = "SSH from the Bastion"
  referenced_security_group_id         = module.bastion_linux.bastion_security_group
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "workspaces_1" {
  security_group_id = aws_security_group.database.id
  description       = "DB access for Workspaces"
  cidr_ipv4         = local.application_data.accounts[local.environment].workspaces_local_cidr1
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "workspaces_2" {
  security_group_id = aws_security_group.database.id
  description       = "DB access for Workspaces"
  cidr_ipv4         = local.application_data.accounts[local.environment].workspaces_local_cidr2
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

resource "aws_vpc_security_group_ingress_rule" "local_vpc" {
  security_group_id = aws_security_group.database.id
  description       = "DB access from local VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = 1571
  ip_protocol       = "tcp"
  to_port           = 1571
}

### Port 1571 rules allow inbound for 10.200.32.0/20 and 10.200.96.0/19 not added as unsure what they are for

### TODO: Add rules with other security groups as source


###############################
# Database EBS Volumes
###############################

resource "aws_ebs_volume" "oradata" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oradata_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].oradata_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oradata" },
  )
}

resource "aws_volume_attachment" "oradata" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.oradata.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oracle" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oracle_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].oracle_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oracle" },
  )
}

resource "aws_volume_attachment" "oracle" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.oracle.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oraarch" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oraarch_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].oradata_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oraarch" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_volume_attachment" "oraarch" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.oraarch.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oratmp" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oratmp_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].oratmp_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oratmp" },
  )
}

resource "aws_volume_attachment" "oratmp" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.oratmp.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "oraredo" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_oraredo_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].oraredo_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-oraredo" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_volume_attachment" "oraredo" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.oraredo.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "share" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_share_size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  # snapshot_id       = local.application_data.accounts[local.environment].share_snapshot_id # This is used for when data is being migrated

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-share" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_volume_attachment" "share" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.share.id
  instance_id = aws_instance.database.id
}


# Pre-reqs - security groups
resource "aws_security_group" "db_ec2_instance_sg" {
  name        = format("%s-sg-%s-ec2-instance", var.env_name, var.db_config.name)
  description = "Controls access to db ec2 instance"
  vpc_id      = var.account_info.vpc_id
  tags = merge(local.tags,
    { Name = lower(format("%s-sg-%s-ec2-instance", var.env_name, var.db_config.name)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_ec2_instance_https_out" {
  security_group_id = aws_security_group.db_ec2_instance_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(local.tags,
    { Name = "https-out" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_ec2_instance_rman" {
  security_group_id = aws_security_group.db_ec2_instance_sg.id
  cidr_ipv4         = var.environment_config.legacy_engineering_vpc_cidr
  from_port         = 1521
  to_port           = 1521
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 1521 to legacy rman"
  tags = merge(local.tags,
    { Name = "legacy-rman-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "db_ec2_instance_rman" {
  security_group_id = aws_security_group.db_ec2_instance_sg.id
  cidr_ipv4         = var.environment_config.legacy_engineering_vpc_cidr
  from_port         = 1521
  to_port           = 1521
  ip_protocol       = "tcp"
  description       = "Allow communication in on port 1521 from legacy rman"
  tags = merge(local.tags,
    { Name = "legacy-rman-in" }
  )
}

# Resources associated to the instance
data "aws_ami" "oracle_db_ami" {
  owners      = [var.platform_vars.environment_management.account_ids["core-shared-services-production"]]
  name_regex  = var.db_config.ami_name_regex
  most_recent = true
}

resource "aws_instance" "db_ec2_primary_instance" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  instance_type               = var.db_config.instance.instance_type
  ami                         = data.aws_ami.oracle_db_ami.id
  vpc_security_group_ids      = [aws_security_group.db_ec2_instance_sg.id, aws_security_group.delius_db_security_group.id]
  subnet_id                   = var.account_config.data_subnet_a_id
  iam_instance_profile        = aws_iam_instance_profile.db_ec2_instanceprofile.name
  associate_public_ip_address = false
  monitoring                  = var.db_config.instance.monitoring
  ebs_optimized               = true
  key_name                    = aws_key_pair.environment_ec2_user_key_pair.key_name
  user_data_base64            = var.db_config.user_data_raw

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  root_block_device {
    volume_type = var.db_config.ebs_volumes.root_volume.volume_type
    volume_size = var.db_config.ebs_volumes.root_volume.volume_size
    iops        = var.db_config.ebs_volumes.iops
    throughput  = var.db_config.ebs_volumes.throughput
    encrypted   = true
    kms_key_id  = var.db_config.ebs_volumes.kms_key_id
    tags        = local.tags
  }

  dynamic "ephemeral_block_device" {
    for_each = { for k, v in var.db_config.ebs_volumes.ebs_non_root_volumes : k => v if v.no_device == true }
    content {
      device_name = ephemeral_block_device.key
      no_device   = true
    }
  }
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-1", var.env_name, var.db_config.name)) },
    { server-type = "delius_core_db" },
    { database = "delius_primarydb" }
  )
}

module "ebs_volume" {
  source = "../ebs_volume"
  for_each = {
    for k, v in var.db_config.ebs_volumes.ebs_non_root_volumes : k => v if v.no_device == false
  }
  availability_zone = aws_instance.db_ec2_primary_instance.availability_zone
  instance_id       = aws_instance.db_ec2_primary_instance.id
  device_name       = each.key
  size              = each.value.volume_size
  iops              = var.db_config.ebs_volumes.iops
  throughput        = var.db_config.ebs_volumes.throughput
  tags              = local.tags
  kms_key_id        = var.db_config.ebs_volumes.kms_key_id

  depends_on = [
    aws_instance.db_ec2_primary_instance
  ]
}

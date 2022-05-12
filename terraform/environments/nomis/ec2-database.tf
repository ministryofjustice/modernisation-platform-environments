#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

module "database" {
  source = "./modules/database"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.application_data.accounts[local.environment].databases

  name = each.key

  always_on          = each.value.always_on
  ami_name           = each.value.ami_name
  asm_data_capacity  = each.value.asm_data_capacity
  asm_flash_capacity = each.value.asm_flash_capacity

  ami_owner              = try(each.value.ami_owner, "${local.environment_management.account_ids["nomis-test"]}")
  asm_data_iops          = try(each.value.asm_data_iops, null)
  asm_data_throughput    = try(each.value.asm_data_throughput, null)
  asm_flash_iops         = try(each.value.asm_flash_iops, null)
  asm_flash_throughput   = try(each.value.asm_data_throughput, null)
  oracle_app_disk_size   = try(each.value.oracle_app_disk_size, null)
  extra_ingress_rules    = try(each.value.extra_ingress_rules, null)
  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id  = aws_security_group.database_common.id
  instance_profile_policies = concat(local.ec2_common_managed_policies, [aws_iam_policy.s3_db_backup_bucket_access.arn])
  key_name                  = aws_key_pair.ec2-user.key_name

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  subnet_set       = local.subnet_set
  tags             = local.tags
}

#------------------------------------------------------------------------------
# Common Security Group for Database Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "database_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for database instances"
  name        = "database-common"
  vpc_id      = data.aws_vpc.shared_vpc.id

  ingress {
    description     = "DB access from weblogic instances"
    from_port       = "1521"
    to_port         = "1521"
    protocol        = "TCP"
    security_groups = [aws_security_group.weblogic_common.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "External access to database port"
    from_port   = "1521"
    to_port     = "1521"
    protocol    = "TCP"
    cidr_blocks = [
      for cidr in local.application_data.accounts[local.environment].database_external_access_cidr : cidr
    ]
  }

  ingress {
    description = "access from Cloud Platform Prometheus server"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [local.application_data.accounts[local.environment].database_external_access_cidr.cloud_platform]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "database-common"
    }
  )
}

#------------------------------------------------------------------------------
# Policy for PUT access to database backups
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_db_backup_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [module.nomis-db-backup-bucket.bucket.arn,
    "${module.nomis-db-backup-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_db_backup_bucket_access" {
  name        = "s3-db-backup-bucket-access"
  path        = "/"
  description = "Policy for access to database backup bucket"
  policy      = data.aws_iam_policy_document.s3_db_backup_bucket_access.json
  tags = merge(
    local.tags,
    {
      Name = "s3-db-backup-bucket-access"
    },
  )
}

##########################################

data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

data "aws_ami" "image" {
  most_recent = true
  owners      = ["${local.environment_management.account_ids["nomis-test"]}"]

  filter {
    name   = "name"
    values = ["nomis_RHEL7_9_2022-05-11T12-46-53*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "test" {
  instance_type               = "t3.medium"
  ami                         = data.aws_ami.image.id
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.ec2-user.key_name
  vpc_security_group_ids = [aws_security_group.database_common.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
  }
  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.image.root_device_name]
    iterator = device
    content {
      device_name = device.value.device_name
      no_device   = true
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "test-rhe7"

    }
  )
}

resource "aws_ebs_volume" "disk" {
  for_each = { for bdm in data.aws_ami.image.block_device_mappings : bdm.device_name => bdm if bdm.device_name != data.aws_ami.image.root_device_name }

  availability_zone = "eu-west-2a"
  encrypted         = true
  snapshot_id       = each.value.ebs.snapshot_id
  type              = "gp3"
}

resource "aws_volume_attachment" "disk" {
  for_each = aws_ebs_volume.disk

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.test.id
}

data "aws_ami" "mp_image" {
  most_recent = true
  owners      = ["374269020027"]

  filter {
    name   = "name"
    values = ["nomis_RHEL7_9_2022-05-11*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "mp_test" {
  instance_type               = "t3.medium"
  ami                         = data.aws_ami.mp_image.id
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.ec2-user.key_name
  vpc_security_group_ids = [aws_security_group.database_common.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
  }
  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.mp_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.mp_image.root_device_name]
    iterator = device
    content {
      device_name = device.value.device_name
      no_device   = true
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "test-rhe7"

    }
  )
}

resource "aws_ebs_volume" "mp_disk" {
  for_each = { for bdm in data.aws_ami.mp_image.block_device_mappings : bdm.device_name => bdm if bdm.device_name != data.aws_ami.mp_image.root_device_name }

  availability_zone = "eu-west-2a"
  encrypted         = true
  snapshot_id       = each.value.ebs.snapshot_id
  type              = "gp3"
}

resource "aws_volume_attachment" "mp_disk" {
  for_each = aws_ebs_volume.mp_disk

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.mp_test.id
}

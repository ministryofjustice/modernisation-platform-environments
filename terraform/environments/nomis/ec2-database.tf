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

  ami_name           = each.value.ami_name
  asm_data_capacity  = each.value.asm_data_capacity
  asm_flash_capacity = each.value.asm_flash_capacity

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
  tags             = local.tags
  subnet_set       = local.subnet_set
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
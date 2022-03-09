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

  asm_data_iops        = try(each.value.asm_data_iops, null)
  asm_data_throughput  = try(each.value.asm_data_throughput, null)
  asm_flash_iops       = try(each.value.asm_flash_iops, null)
  asm_flash_throughput = try(each.value.asm_data_throughput, null)
  oracle_app_disk_size = try(each.value.oracle_app_disk_size, null)
  extra_ingress_rules  = try(each.value.extra_ingress_rules, null)
  termination_protection = try(each.termination_protection, null)

  common_security_group_id = aws_security_group.database_common.id
  instance_profile_name    = aws_iam_instance_profile.ec2_database_profile.name
  key_name                 = aws_key_pair.ec2-user.key_name

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  tags             = local.tags
  subnet_set       = local.subnet_set
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 database instances
# This is based on the ec2-common-profile but also gives access to an S3 bucket
# in which database backups are stored
#------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_database_role" {
  name                 = "ec2-database-role"
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
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.ec2_common_policy.arn
  ]

  tags = merge(
    local.tags,
    {
      Name = "ec2-database-role"
    },
  )
}

# attach database backup bucket access policy inline
# we managed the attachment separately as additional inline policies are attached
# to the role in the nomis_stack module
resource "aws_iam_role_policy" "s3_db_backup_bucket_access" {
  name   = "nomis-db-backup-bucket-access"
  role   = aws_iam_role.ec2_database_role.name
  policy = data.aws_iam_policy_document.s3_db_backup_bucket_access.json
}

# create instance profile from IAM role
resource "aws_iam_instance_profile" "ec2_database_profile" {
  name = "ec2-database-profile"
  role = aws_iam_role.ec2_database_role.name
  path = "/"
}

data "aws_iam_policy_document" "s3_db_backup_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [module.nomis-db-backup-bucket.bucket.arn,
    "${module.nomis-db-backup-bucket.bucket.arn}/*"]
  }
}
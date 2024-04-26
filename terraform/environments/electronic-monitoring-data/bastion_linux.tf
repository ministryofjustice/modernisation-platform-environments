locals {
  public_key_data = jsondecode(file("${path.module}/bastion_linux.json"))
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "rds_bastion" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v4.2.1"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name = "rds-bastion"

  # public keys
  public_key_data = local.public_key_data.keys[local.environment]

  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration

  # bastion
  instance_name = "s3_rds_bastion"

  allow_ssh_commands = true
  app_name      = var.networking[0].application
  business_unit = local.vpc_name
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"

  # tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "s3_rds_bastion" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v4.2.1"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name = "s3-rds-bastion"

  # public keys
  public_key_data = local.public_key_data.keys[local.environment]

  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration

  # bastion
  instance_name = "s3_rds_bastion"

  allow_ssh_commands = true
  app_name      = var.networking[0].application
  business_unit = local.vpc_name
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"
  volume_size   = 20

  # tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

# # tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
# module "s3_bastion" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v4.2.1"

#   providers = {
#     aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
#     aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
#   }

#   # s3 - used for logs and user ssh public keys
#   bucket_name = "s3-bastion"

#   # public keys
#   public_key_data = local.public_key_data.keys[local.environment]

#   # logs
#   log_auto_clean       = "Enabled"
#   log_standard_ia_days = 30  # days before moving to IA storage
#   log_glacier_days     = 60  # days before moving to Glacier
#   log_expiry_days      = 180 # days before log expiration

#   # bastion
#   instance_name = "s3_bastion"

#   allow_ssh_commands = true
#   app_name      = var.networking[0].application
#   business_unit = local.vpc_name
#   subnet_set    = local.subnet_set
#   environment   = local.environment
#   region        = "eu-west-2"
#   volume_size   = 1000

#   # tags
#   tags_common = local.tags
#   tags_prefix = terraform.workspace
# }

locals {
  rds_access = [
    module.s3_rds_bastion.bastion_security_group,
    module.rds_bastion.bastion_security_group
  ]
  s3_access = [
    module.s3_rds_bastion.bastion_iam_role.name,
    # module.s3_bastion.bastion_iam_role.name
  ]
  all_instances = [
    module.rds_bastion.bastion_iam_role.name,
    module.s3_rds_bastion.bastion_iam_role.name,
    # module.s3_bastion.bastion_iam_role.name
  ]
}

resource "aws_vpc_security_group_egress_rule" "access_ms_sql_server" {
  for_each = { for idx, sg_id in local.rds_access : idx => sg_id }

  security_group_id = each.value
  description       = "EC2 MSSQL Access"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "vpc_access" {
  for_each = { for idx, sg_id in local.rds_access : idx => sg_id }

  security_group_id = each.value
  description       = "Reach vpc endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "rds_via_vpc_access" {
  for_each = { for idx, sg_id in local.rds_access : idx => sg_id }

  security_group_id = aws_security_group.db.id
  description       = "EC2 instance connection to RDS"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  referenced_security_group_id = each.value
}

data "aws_iam_policy_document" "ec2_s3_policy" {
  statement {
    sid    = "AllowListDataStore"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.data_store.arn,
    ]
  }
  statement {
    sid    = "AllowReadDataStore"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.data_store.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  for_each = { for idx, sg_id in local.rds_access : idx => sg_id }

  name   = "ec2-s3-policy-${each.value}"
  role   = each.value
  policy = data.aws_iam_policy_document.ec2_s3_policy.json
}

resource "aws_iam_policy_attachment" "ssm-attachments" {
  name       = "ssm-attach-instance-role"
  roles      = local.all_instances
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

locals {
  public_key_data = jsondecode(file("${path.module}/bastion_linux.json"))
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "rds_bastion" {
  count  = local.is-production || local.is-development ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=1eaf3c9"
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
  # instance_name = "s3_rds_bastion_linux"

  allow_ssh_commands = true
  app_name           = var.networking[0].application
  business_unit      = local.vpc_name
  subnet_set         = local.subnet_set
  environment        = local.environment
  region             = "eu-west-2"
  volume_size        = 20
  # tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

resource "aws_vpc_security_group_egress_rule" "access_ms_sql_server" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id = module.rds_bastion[0].bastion_security_group
  description       = "EC2 MSSQL Access"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "vpc_access" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id = module.rds_bastion[0].bastion_security_group
  description       = "Reach vpc endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "rds_via_vpc_access" {
  count = local.is-production || local.is-development ? 1 : 0

  security_group_id            = aws_security_group.db[0].id
  description                  = "EC2 instance connection to RDS"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = module.rds_bastion[0].bastion_security_group
}

data "aws_iam_policy_document" "ec2_s3_policy" {
  statement {
    sid    = "AllowListDataStore"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3-data-bucket.bucket.arn,
    ]
  }
  statement {
    sid    = "AllowReadDataStore"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${module.s3-data-bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  count = local.is-production || local.is-development ? 1 : 0

  name   = "ec2-s3-policy"
  role   = module.rds_bastion[0].bastion_iam_role.name
  policy = data.aws_iam_policy_document.ec2_s3_policy.json
}

resource "aws_iam_role_policy" "zip_s3_policy" {

  name   = "zip_s3_policy"
  role   = module.zip_bastion.bastion_iam_role.name
  policy = data.aws_iam_policy_document.zip_s3_policy.json
}

data "aws_iam_policy_document" "zip_s3_policy" {
  statement {
    sid    = "AllowListDataStore"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3-data-bucket.bucket.arn,
    ]
  }
  statement {
    sid    = "AllowReadAndPutDataStore"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${module.s3-data-bucket.bucket.arn}/*",
    ]
  }
  statement {
    sid    = "AllowListUnzipStore"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.s3-unzipped-files-bucket.bucket.arn
    ]
  }
  statement {
    sid    = "AllowPutUnzipStore"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.s3-unzipped-files-bucket.bucket.arn}/*"
    ]
  }
  statement {
    sid    = "AllowPutSercoExportStore"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.s3-serco-export-bucket.bucket_arn}/*"
    ]
  }
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "zip_bastion" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=1eaf3c9"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name   = "zip-bastion"
  instance_name = "zip_bastion_linux"
  instance_type = "m5.large"
  # public keys
  public_key_data = local.public_key_data.keys[local.environment]

  # logs
  log_auto_clean       = "Enabled"
  log_standard_ia_days = 30  # days before moving to IA storage
  log_glacier_days     = 60  # days before moving to Glacier
  log_expiry_days      = 180 # days before log expiration

  allow_ssh_commands = true
  # autoscaling_cron   = {
  #   "down": "0 20 * * *",
  #   "up": "*/30 * * * *"
  # }
  app_name      = var.networking[0].application
  business_unit = local.vpc_name
  subnet_set    = local.subnet_set
  environment   = local.environment
  region        = "eu-west-2"
  volume_size   = 1500
  # tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

resource "aws_vpc_security_group_egress_rule" "zip_bastion_vpc_access" {
  security_group_id = module.zip_bastion.bastion_security_group
  description       = "Reach vpc endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}
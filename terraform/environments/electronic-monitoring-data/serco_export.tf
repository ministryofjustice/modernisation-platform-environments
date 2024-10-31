module "s3-serco-export-bucket" {
  source             = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"
  bucket_prefix      = "${local.bucket_prefix}-serco-export-"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }
  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-data/"
  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 7
      }
    }
  ]

  tags = local.tags
}

resource "aws_s3_bucket_policy" "serco_export_s3_policy" {
  bucket = module.s3-serco-export-bucket.bucket.id
  policy = data.aws_iam_policy_document.serco_export_s3_policy.json
}

data "aws_iam_policy_document" "serco_export_s3_policy" {
  statement {
    sid     = "AllowedIP"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${module.s3-serco-export-bucket.bucket.arn}/*"
    ]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = "2.31.200.13/32"
    }
  }
}

resource "aws_iam_role_policy" "serco_export_bastion_s3_policy" {
  name   = "serco_export_bastion_s3_policy"
  role   = module.serco_export_bastion.bastion_iam_role.name
  policy = data.aws_iam_policy_document.serco_export_bastion_s3_policy.json
}

data "aws_iam_policy_document" "serco_export_bastion_s3_policy" {
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
  statement {
    sid    = "AllowPutSercoExportStore"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.s3-serco-export-bucket.bucket.arn}/*"
    ]
  }
}

# tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "serco_export_bastion" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=95ed3c3"

  providers = {
    aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
  }

  # s3 - used for logs and user ssh public keys
  bucket_name   = "serco-export-bastion"
  instance_name = "serco_export_bastion_linux"
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
  volume_size   = 5
  # tags
  tags_common = local.tags
  tags_prefix = terraform.workspace
}

resource "aws_vpc_security_group_egress_rule" "serco_export_bastion_vpc_access" {
  security_group_id = module.serco_export_bastion.bastion_security_group
  description       = "Reach vpc endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

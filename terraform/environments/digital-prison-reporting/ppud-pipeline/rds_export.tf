locals {
  rds_export_bucket_lifecycle_rule = [
    {
      id      = "main"
      enabled = "Disabled"
      prefix  = ""

      transition = [
        {
          days          = 90
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
      expiration = {
        days = 730
      }
      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
      noncurrent_version_expiration = {
        days = 730
      }
  }]

}

# Security group for the rds instance
resource "aws_security_group" "ppud_db" {
  # checkov:skip=CKV2_AWS_5:Ensure that Security Groups are attached to another resource; skip as attached to VPC
  name        = "ppud-pipeline-sg"
  description = "Security group for RDS instance in the PPUD pipeline"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      resource-type = "Security Group"
    }
  )

}

# Allow access to the rds instance from the vpc
resource "aws_vpc_security_group_ingress_rule" "ppud_db_ingress" {
  security_group_id = aws_security_group.ppud_db.id
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  description       = "Allow access to the RDS instance from the VPC in the PPUD pipeline"

}

# Sets up RDS export infrastructure for PPUD pipeline
module "ppud_rds_export" {
  source = "git::https://github.com/ministryofjustice/terraform-rds-export?ref=ec51378f6e284526745ae277d85dcbf7033fe9d0"

  providers = {
    aws = aws
  }

  name                           = local.short_name
  database_refresh_mode          = "incremental"
  vpc_id                         = data.aws_vpc.shared.id
  database_subnet_ids            = data.aws_subnets.shared-private.ids
  kms_key_arn                    = module.ppud_kms.key_arn
  master_user_secret_id          = module.ppud_rds_export_secret.secret_id
  environment                    = local.environment
  output_parquet_file_size       = 50
  db_name                        = "${local.short_name}_${local.environment}"
  get_views                      = false
  bucket_namespace               = "account-regional"
  lifecycle_rule_backup_uploads  = local.rds_export_bucket_lifecycle_rule
  lifecycle_rule_parquet_exports = local.rds_export_bucket_lifecycle_rule


  tags = merge(
    local.tags,
    {
      resource-type = "RDS Export Module"
    }
  )

}

# # Create a resource to subscribe to SNS topic for Slack notification
# resource "aws_sns_topic_subscription" "sfn_events" {
#   topic_arn = module.ppud_rds_export.sns_topic_arn
#   protocol  = "https"
#   endpoint  = data.aws_secretsmanager_secret_version.ppud_slack_webhook.secret_string
# }

# Security group for the rds instance
resource "aws_security_group" "ppud_db" {
  name        = "ppud_pipeline_sg"
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
resource "aws_security_group_rule" "ppud_db_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.ppud_db.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  description       = "Allow access to the RDS instance from the VPC in the PPUD pipeline"

}

# Sets up RDS export infrastructure for PPUD pipeline
module "ppud_rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=bf54b5dd6041348cb6d0486c046e6b97c9631d76"

  providers = {
    aws = aws
  }

  name                     = local.short_name
  database_refresh_mode    = "incremental"
  vpc_id                   = data.aws_vpc.shared.id
  database_subnet_ids      = data.aws_subnets.shared-private.ids
  kms_key_arn              = module.ppud_kms.key_arn
  master_user_secret_id    = module.ppud_rds_export_secret.secret_id
  environment              = local.environment
  output_parquet_file_size = 50
  db_name                  = "${local.short_name}_${local.environment}"
  get_views                = true
  bucket_namespace         = "account-regional"

  tags = merge(
    local.tags,
    {
      resource-type = "RDS Export Module"
    }
  )

}

# Create a resource to subscribe to SNS topic
# Slack notifications
resource "aws_sns_topic_subscription" "sfn_events" {
  topic_arn = module.ppud_rds_export.sns_topic_arn
  protocol  = "https"
  endpoint  = module.ppud_slack_webhook.secret_string
}

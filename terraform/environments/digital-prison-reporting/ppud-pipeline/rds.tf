# Security group for the RDS instance
resource "aws_security_group" "db" {
  # checkov:skip=CKV2_AWS_5: Attached to VPC
  name        = "${local.component_name}-${local.environment}"
  description = "Security group for RDS instance ${local.component_name}-${local.environment}"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

# Allow access to the RDS instance from the VPC
resource "aws_security_group_rule" "db_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks = [data.aws_vpc.shared.cidr_block]
  description       = "Allow access to the RDS instance from the VPC"
}

module "rds_export" {
  # using source ref whilst testing
  source = "github.com/ministryofjustice/terraform-rds-export?ref=26c16ad6944e91a147280d4bff088929d17f6b21"

  providers = {
    aws = aws
  }

  name                     = local.component_name
  database_refresh_mode    = "incremental"
  vpc_id                   = data.aws_vpc.shared.id
  database_subnet_ids      = data.aws_subnets.shared-private.ids
  kms_key_arn              = module.rds_export_kms.key_arn
  master_user_secret_id    = module.rds_export_secret.secret_arn
  environment              = local.environment
  output_parquet_file_size = 50
  get_views                = true
  db_name = "ppud_${replace(local.environment, "-", "_")}"

  tags = local.tags
}

# Create a resource to subscribe to SNS topic
# Slack notifications
resource "aws_sns_topic_subscription" "sfn_events" {
  topic_arn = module.rds_export.sns_topic_arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.slack_webhook.secret_string
}
# KMS Key ID for Kinesis Stream
data "aws_kms_key" "kinesis_kms_key" {
  key_id = aws_kms_key.kinesis-kms-key.arn
}

# Source Nomis Secrets
data "aws_secretsmanager_secret" "nomis" {
  name = aws_secretsmanager_secret.nomis.id

  depends_on = [aws_secretsmanager_secret_version.nomis]
}

data "aws_secretsmanager_secret_version" "nomis" {
  secret_id = data.aws_secretsmanager_secret.nomis.id

  depends_on = [aws_secretsmanager_secret.nomis]
}

# AWS _IAM_ Policy
data "aws_iam_policy" "rds_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# Get APIGateway Endpoint ID
data "aws_vpc_endpoint" "api" {
  provider     = aws.core-vpc
  vpc_id       = data.aws_vpc.shared.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.execute-api"
  }
}

# Get slack integration url
data "aws_secretsmanager_secret" "slack_integration" {
  count      = local.enable_slack_alerts ? 1 : 0
  depends_on = [module.slack_alerts_url]
  name       = "${local.project}-slack-alerts-url-${local.environment}"
}

data "aws_secretsmanager_secret_version" "slack_integration" {
  count     = local.enable_slack_alerts ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.slack_integration[0].id
}

# Get pagerduty integration url
data "aws_secretsmanager_secret" "pagerduty_integration" {
  count      = local.enable_pagerduty_alerts ? 1 : 0
  depends_on = [module.pagerduty_integration_key]
  name       = "${local.project}-pagerduty-integration-key-${local.environment}"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration" {
  count     = local.enable_pagerduty_alerts ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration[0].id
}

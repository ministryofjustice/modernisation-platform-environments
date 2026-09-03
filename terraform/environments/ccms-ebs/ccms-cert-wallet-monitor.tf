resource "aws_ssm_document" "certificate_wallet_expiry_check" {
  name            = "CCMS-Certificate-Wallet-Expiry-Check"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm/ccms-ssm-document-certificate-wallet-expiry-check.yaml")
}

# Placeholder value - must be set manually in the AWS console/CLI by the DBA/AppOps team, never committed here
resource "aws_ssm_parameter" "ebsdb_wallet_password" {
  count = local.environment == "production" ? 1 : 0

  name        = "/ccms-ebs/${local.environment}/certificate-monitor/ebsdb-wallet-password"
  description = "Password for the EBS DB Oracle wallet used by the certificate expiry check"
  type        = "SecureString"
  value       = "changeme"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(local.tags,
    { Name = "ebsdb-wallet-password" }
  )
}

# Placeholder value - must be set manually in the AWS console/CLI by the DBA/AppOps team, never committed here
resource "aws_ssm_parameter" "ebsapps_keystore_password" {
  count = local.environment == "production" ? 1 : 0

  name        = "/ccms-ebs/${local.environment}/certificate-monitor/ebsapps-keystore-password"
  description = "Password for the EBS apps adkeystore.dat used by the certificate expiry check"
  type        = "SecureString"
  value       = "changeme"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(local.tags,
    { Name = "ebsapps-keystore-password" }
  )
}

resource "aws_iam_policy" "certificate_wallet_expiry_check_sns_publish" {
  count = local.environment == "production" ? 1 : 0

  name        = "certificate-wallet-expiry-check-sns-publish-${local.environment}"
  description = "Allows EC2 instances to publish certificate expiry alerts to the cw_alerts SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.cw_alerts.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "certificate_wallet_expiry_check_sns_publish" {
  count = local.environment == "production" ? 1 : 0

  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = one(aws_iam_policy.certificate_wallet_expiry_check_sns_publish[*].arn)
}

# EBS DB Oracle wallet check - path/password confirmed for production only (per Jira CC-2979 comments).
# Do not extend to other environments until the DBA team confirms the wallet path for each.
resource "aws_ssm_association" "certificate_wallet_expiry_check_ebsdb" {
  count = local.environment == "production" ? 1 : 0

  name             = aws_ssm_document.certificate_wallet_expiry_check.name
  association_name = "certificate-wallet-expiry-check-ebsdb"

  parameters = {
    certType              = "orapki"
    keystorePath          = "/CCMS/EBS/techst/1210/owm/wallets/oracle/rptest"
    passwordParameterName = one(aws_ssm_parameter.ebsdb_wallet_password[*].name)
    snsTopicArn           = aws_sns_topic.cw_alerts.arn
    thresholdDays         = "90"
  }

  targets {
    key    = "tag:Name"
    values = [lower(format("ec2-%s-%s-ebsdb", local.application_name, local.environment))]
  }

  apply_only_at_cron_interval = false
  schedule_expression         = "cron(0 6 ? * MON *)"
}

# CCMS/CWA EBS apps adkeystore.dat check - path confirmed for production only (per Jira CC-2979 ticket description).
# Do not extend to other environments until the DBA team confirms the keystore path for each.
resource "aws_ssm_association" "certificate_wallet_expiry_check_ebsapps" {
  count = local.environment == "production" ? 1 : 0

  name             = aws_ssm_document.certificate_wallet_expiry_check.name
  association_name = "certificate-wallet-expiry-check-ebsapps"

  parameters = {
    certType              = "keytool"
    keystorePath          = "/u03/oracle/prod/ebsprod/apps/apps_st/appl/admin/adkeystore.dat"
    passwordParameterName = one(aws_ssm_parameter.ebsapps_keystore_password[*].name)
    snsTopicArn           = aws_sns_topic.cw_alerts.arn
    thresholdDays         = "90"
  }

  targets {
    key    = "tag:Name"
    values = [lower(format("ec2-%s-%s-ebsapps-*", local.application_name, local.environment))]
  }

  apply_only_at_cron_interval = false
  schedule_expression         = "cron(0 6 ? * MON *)"
}

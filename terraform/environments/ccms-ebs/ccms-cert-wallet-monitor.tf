locals {
  # Environment files sourced before each check, per environment. The apps env files are named per host,
  # so $(hostname -s) is resolved on each apps node.
  ebsdb_env_files = {
    development   = "/CCMS/EBS/techst/1210/EBSDB_ccms-ebs-db.env"
    test          = "/CCMS/EBS/techst/1210/EBSE10_ccms-ebs-db.env"
    preproduction = "/CCMS/EBS/techst/1210/EBSE10_ccms-ebs-db.env"
    production    = "/CCMS/EBSPROD/techst/1210/EBSPROD_ccms-ebs-db.env"
  }

  ebsapps_env_files = {
    development   = "/u03/ebs/apps_st/appl/APPSEBSDB_$(hostname -s).env"
    test          = "/u03/ebs/apps_st/appl/APPSEBSE10_$(hostname -s).env"
    preproduction = "/u03/ebs/apps_st/appl/APPSEBSE10_$(hostname -s).env"
    production    = "/u03/oracle/prod/ebsprod/apps/apps_st/appl/APPSEBSPROD_$(hostname -s).env"
  }

  # Same Name tags as the EBS apps instances - SSM tag targets match exactly, not by wildcard
  ebsapps_instance_names = [
    for i in range(local.application_data.accounts[local.environment].ebsapps_no_instances) :
    lower(format("ec2-%s-%s-ebsapps-%s", local.application_name, local.environment, i + 1))
  ]

  # Keystores to check, resolved on the host from the variables set by the env file
  certificate_wallet_expiry_checks = {
    ebsdb-wallet = {
      cert_type     = "orapki"
      keystore_path = "$ORACLE_HOME/owm/wallets/oracle"
      env_file      = local.ebsdb_env_files[local.environment]
      secret_key    = "ebsdb_wallet_password"
      target_names  = [lower(format("ec2-%s-%s-ebsdb", local.application_name, local.environment))]
    }
    ebsapps-adkeystore = {
      cert_type     = "keytool"
      keystore_path = "$APPL_TOP/admin/adkeystore.dat"
      env_file      = local.ebsapps_env_files[local.environment]
      secret_key    = "ebsapps_keystore_password"
      target_names  = local.ebsapps_instance_names
    }
    ebsapps-cacerts = {
      cert_type     = "keytool"
      keystore_path = "$OA_JRE_TOP/lib/security/cacerts"
      env_file      = local.ebsapps_env_files[local.environment]
      secret_key    = "ebsapps_cacerts_password"
      target_names  = local.ebsapps_instance_names
    }
  }
}

resource "aws_ssm_document" "certificate_wallet_expiry_check" {
  name            = "CCMS-Certificate-Wallet-Expiry-Check"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm/ccms-ssm-document-certificate-wallet-expiry-check.yaml")
}

# Wallet/keystore passwords - placeholder values, populated manually by the DBA/AppOps team
resource "aws_secretsmanager_secret" "certificate_monitor" {
  name        = "${local.application_name}-certificate-monitor"
  description = "Passwords for the EBS DB wallet and EBS apps keystores used by the certificate expiry check"

  tags = merge(local.tags,
    { Name = "${local.application_name}-certificate-monitor-${local.environment}" }
  )
}

resource "aws_secretsmanager_secret_version" "certificate_monitor" {
  secret_id = aws_secretsmanager_secret.certificate_monitor.id

  secret_string = jsonencode({
    "ebsdb_wallet_password"     = "",
    "ebsapps_keystore_password" = "",
    "ebsapps_cacerts_password"  = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

resource "aws_iam_policy" "certificate_wallet_expiry_check" {
  name        = "certificate-wallet-expiry-check-${local.environment}"
  description = "Allows EC2 instances to read the certificate monitor secret and publish expiry alerts to the cw_alerts SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.certificate_monitor.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.cw_alerts.arn]
      },
      {
        # cw_alerts is encrypted with this key
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource = [aws_kms_key.cloudwatch_sns_alerts_key.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "certificate_wallet_expiry_check" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.certificate_wallet_expiry_check.arn
}

resource "aws_ssm_association" "certificate_wallet_expiry_check" {
  for_each = local.certificate_wallet_expiry_checks

  name             = aws_ssm_document.certificate_wallet_expiry_check.name
  association_name = "certificate-wallet-expiry-check-${each.key}"

  parameters = {
    certType      = each.value.cert_type
    keystorePath  = each.value.keystore_path
    envFile       = each.value.env_file
    secretId      = aws_secretsmanager_secret.certificate_monitor.name
    secretKey     = each.value.secret_key
    snsTopicArn   = aws_sns_topic.cw_alerts.arn
    thresholdDays = "90"
  }

  targets {
    key    = "tag:Name"
    values = each.value.target_names
  }

  apply_only_at_cron_interval = false
  schedule_expression         = "cron(0 6 ? * MON *)"
}

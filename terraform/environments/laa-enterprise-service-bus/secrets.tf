#####################################################################################
### Secrets used for CWA Extract Lambda Functions ###
#####################################################################################

resource "aws_secretsmanager_secret" "cwa_procedures_config" {
  name = "cwa-extract-lambda-procedures-config-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-procedures-config"
    }
  )
}

resource "aws_secretsmanager_secret" "cwa_db_secret" {
  name = "cwa-extract-lambda-db-secret-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-db-secret"
    }
  )
}

resource "aws_secretsmanager_secret" "cwa_table_name_secret" {
  name = "cwa-file-transfer-table-lambda-secret-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cwa-file-transfer-table-lambda-secret"
    }
  )
}

#####################################################################################
### Secrets used for CCMS Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "ccms_db_mp_credentials" {
  name = "ccms-db-mp-credentials-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccms-db-mp-credentials"
    }
  )
}

resource "aws_secretsmanager_secret" "ccms_procedures_config" {
  name = "ccms-provider-lambda-procedures-config-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccms-provider-lambda-procedures-config"
    }
  )
}

#####################################################################################
### Secrets used for MAAT Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "maat_db_mp_credentials" {
  name = "maat-db-mp-credentials-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-maat-db-mp-credentials"
    }
  )
}

resource "aws_secretsmanager_secret" "maat_procedures_config" {
  name = "maat-provider-lambda-procedures-config-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-maat-provider-lambda-procedures-config"
    }
  )
}

#####################################################################################
### Secrets used for CCR Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "ccr_db_mp_credentials" {
  name = "ccr-db-mp-credentials-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccr-db-mp-credentials"
    }
  )
}

resource "aws_secretsmanager_secret" "ccr_procedures_config" {
  name = "ccr-provider-lambda-procedures-config-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccr-provider-lambda-procedures-config"
    }
  )
}

#####################################################################################
### Secrets used for CCLF Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "cclf_db_mp_credentials" {
  name = "cclf-db-mp-credentials-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cclf-db-mp-credentials"
    }
  )
}

resource "aws_secretsmanager_secret" "cclf_procedures_config" {
  name = "cclf-provider-lambda-procedures-config-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cclf-provider-lambda-procedures-config"
    }
  )
}

#####################################################################################
### Secrets used for Cloudwatch Alert Lambda Functions ###
#####################################################################################

resource "aws_secretsmanager_secret" "slack_alert_channel_webhook" {
  name = "slack-alert-channel-webhook-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-slack-alert-channel-webhook"
    }
  )
}

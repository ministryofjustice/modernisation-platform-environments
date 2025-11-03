#####################################################################################
### Secrets used for CWA Extract Lambda Functions ###
#####################################################################################
resource "aws_secretsmanager_secret" "patch_cwa_db_secret" {
  count = local.environment == "test" ? 1 : 0
  name  = "patch-cwa-extract-lambda-db-secret-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda-db-secret"
    }
  )
}


#####################################################################################
### Secrets used for CCMS Extract Lambda Function ###
#####################################################################################

resource "aws_secretsmanager_secret" "patch_ccms_db_mp_credentials" {
  count = local.environment == "test" ? 1 : 0
  name  = "patch-ccms-db-mp-credentials-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-ccms-db-mp-credentials"
    }
  )
}

resource "aws_secretsmanager_secret" "patch_ccms_procedures_config" {
  count = local.environment == "test" ? 1 : 0
  name  = "patch-ccms-provider-lambda-procedures-config-${local.environment}"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-ccms-provider-lambda-procedures-config"
    }
  )
}

# Get modernisation account id from ssm parameter
data "aws_ssm_parameter" "modernisation_platform_account_id" {
  provider = aws.original-session
  name     = "modernisation_platform_account_id"
}

# Get secret by arn for environment management
data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

# Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

resource "aws_secretsmanager_secret" "maatdb_password_secret_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_MAATDB_DBPASSWORD_MLA1"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maatdb_password_secret_name" {
  secret_id     = aws_secretsmanager_secret.maatdb_password_secret_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "app_master_password_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_MASTER_PASSWORD"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "app_master_password_name" {
  secret_id     = aws_secretsmanager_secret.app_master_password_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "app_salt_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_SALT"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "app_salt_name" {
  secret_id     = aws_secretsmanager_secret.app_salt_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "app_derivation_iterations_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_DERIVATION_ITERATIONS"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "app_derivation_iterations_name" {
  secret_id     = aws_secretsmanager_secret.app_derivation_iterations_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "gtm_id_secret_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_MLRA_GOOGLE_TAG_MANAGER_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "gtm_id_secret_name" {
  secret_id     = aws_secretsmanager_secret.gtm_id_secret_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "infox_client_secret_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_INFOX_CLIENT_SECRET"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "infox_client_secret_name" {
  secret_id     = aws_secretsmanager_secret.infox_client_secret_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_api_client_id_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_MAAT_API_CLIENT_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_api_client_id_name" {
  secret_id     = aws_secretsmanager_secret.maat_api_client_id_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_api_client_secret_name" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "APP_MAAT_API_CLIENT_SECRET"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_api_client_secret_name" {
  secret_id     = aws_secretsmanager_secret.maat_api_client_secret_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

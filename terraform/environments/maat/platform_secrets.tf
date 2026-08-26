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

resource "aws_secretsmanager_secret" "maat_app_orch_client_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ORCH_CLIENT_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_orch_client_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_orch_client_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}


resource "aws_secretsmanager_secret" "maat_app_orch_endpoint" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ORCH_ENDPOINT"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_orch_endpoint" {
  secret_id     = aws_secretsmanager_secret.maat_app_orch_endpoint.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# /maat/APP_ORCH_OAUTH_SCOPE
resource "aws_secretsmanager_secret" "maat_app_orch_oauth_scope" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ORCH_OAUTH_SCOPE"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_orch_oauth_scope" {
  secret_id     = aws_secretsmanager_secret.maat_app_orch_oauth_scope.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# /maat/APP_ORCH_CLIENT_SECRET
resource "aws_secretsmanager_secret" "maat_app_orch_client_secret" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ORCH_CLIENT_SECRET"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_orch_client_secret" {
  secret_id     = aws_secretsmanager_secret.maat_app_orch_client_secret.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_bc_client_user_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_BC_CLIENT_USER_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_bc_client_user_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_bc_client_user_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_google_analytics_tag_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_MAAT_GOOGLE_ANALYTICS_4_TAG_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_google_analytics_tag_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_google_analytics_tag_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_bc_client_orig_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_BC_CLIENT_ORIG_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_bc_client_orig_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_bc_client_orig_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_db_password" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_DB_PASSWORD"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_db_password" {
  secret_id     = aws_secretsmanager_secret.maat_app_db_password.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_caa_client_secret" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_CAA_CLIENT_SECRET"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_caa_client_secret" {
  secret_id     = aws_secretsmanager_secret.maat_app_caa_client_secret.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_caa_client_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_CAA_CLIENT_ID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_caa_client_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_caa_client_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_db_user_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_DB_USERID"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_db_user_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_db_user_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_caa_endpoint" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_CAA_ENDPOINT"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_caa_endpoint" {
  secret_id     = aws_secretsmanager_secret.maat_app_caa_endpoint.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_bc_service_name" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_BC_SERVICE_NAME"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_bc_service_name" {
  secret_id     = aws_secretsmanager_secret.maat_app_bc_service_name.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_ats_client_secret" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ATS_CLIENT_SECRET"

  tags = merge(
    local.tags,
    {
      Name = "application-env-secret-${upper(local.application_name)}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_ats_client_secret" {
  secret_id     = aws_secretsmanager_secret.maat_app_ats_client_secret.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_ats_client_id" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ATS_CLIENT_ID"

  tags = merge(
    local.tags,
    {
      Name            = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_ats_client_id" {
  secret_id     = aws_secretsmanager_secret.maat_app_ats_client_id.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_ats_oauth_scope" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_ATS_OAUTH_SCOPE"

  tags = merge(
    local.tags,
    {
      Name            = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_ats_oauth_scope" {
  secret_id     = aws_secretsmanager_secret.maat_app_ats_oauth_scope.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_master_password" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_MASTER_PASSWORD"

  tags = merge(
    local.tags,
    {
      Name            = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_master_password" {
  secret_id     = aws_secretsmanager_secret.maat_app_master_password.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_salt" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_SALT"

  tags = merge(
    local.tags,
    {
      Name            = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_salt" {
  secret_id     = aws_secretsmanager_secret.maat_app_salt.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "maat_app_derivation_iterations" {
  #checkov:skip=CKV2_AWS_57: "Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ignore - Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name = "maat/APP_DERIVATION_ITERATIONS"

  tags = merge(
    local.tags,
    {
      Name            = "application-env-secret-${upper(local.application_name)}"
      rotation_reason = "rotation_not_required_static_application_env"
    }
  )
}

resource "aws_secretsmanager_secret_version" "maat_app_derivation_iterations" {
  secret_id     = aws_secretsmanager_secret.maat_app_derivation_iterations.id
  secret_string = "replace in console"

  lifecycle {
    ignore_changes = [secret_string]
  }
}


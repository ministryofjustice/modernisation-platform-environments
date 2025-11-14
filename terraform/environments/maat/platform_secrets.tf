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

  lifecycle {
    ignore_changes = [secret_string]
  }
}



##############################################
### LinOTP Active Directory Integration
###
### Uses existing lambda.workspace service account
### for LinOTP LDAP resolver to query AD
##############################################

##############################################
### Reference Existing AD Service Account
### (created in parent module: xxx-new-service-account.tf)
##############################################

# Reference existing SSM parameter for lambda.workspace password
data "aws_ssm_parameter" "lambda_service_account_password" {
  name = "/laa-workspaces/${local.environment}/ad-service-account-password"
}

# Create Secrets Manager secret for ECS (ECS can't use SSM parameters directly in task definitions)
resource "aws_secretsmanager_secret" "linotp_ad_bind_password" {
  count = local.environment == "development" ? 1 : 0

  name                    = "${local.application_name}/${local.environment}/linotp-ad-bind-password"
  description             = "LinOTP AD bind password (mirrors lambda.workspace from SSM for ECS compatibility)"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}/${local.environment}/linotp-ad-bind-password",
      "MirroredFrom" = "SSM:/laa-workspaces/${local.environment}/ad-service-account-password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "linotp_ad_bind_password" {
  count = local.environment == "development" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.linotp_ad_bind_password[0].id
  secret_string = data.aws_ssm_parameter.lambda_service_account_password.value

  lifecycle {
    # Don't update if SSM changes - manual sync required to avoid breaking running tasks
    ignore_changes = [secret_string]
  }
}

##############################################
### Update IAM permissions for AD bind secret
##############################################

resource "aws_iam_role_policy" "ecs_task_execution_ad_secret" {
  count = local.environment == "development" ? 1 : 0

  name = "${local.application_name}-${local.environment}-ecs-exec-ad-secret"
  role = aws_iam_role.ecs_task_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ADBindSecretAccess"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.linotp_ad_bind_password[0].arn
        ]
      }
    ]
  })
}

##############################################
### Outputs
##############################################

output "linotp_ad_service_account_info" {
  description = "LinOTP AD service account configuration"
  value = local.environment == "development" ? {
    status       = "✅ Using existing lambda.workspace service account"
    username     = "lambda.workspace"
    domain       = "LAAWORKSPACES"
    bind_dn      = "CN=lambda.workspace,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local"
    ssm_source   = "/laa-workspaces/development/ad-service-account-password"
    secrets_mgr  = aws_secretsmanager_secret.linotp_ad_bind_password[0].name
    note         = "No additional AD account creation required - reusing existing service account"
  } : null
}

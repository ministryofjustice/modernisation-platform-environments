##############################################
### LinOTP Active Directory Integration
###
### Creates service account credentials for
### LinOTP LDAP resolver to query AD
##############################################

##############################################
### AD Service Account Password
### (Create service account manually in AD first)
##############################################

# Generate random password for LinOTP service account
resource "random_password" "linotp_ad_bind_password" {
  count = local.environment == "development" ? 1 : 0

  length  = 32
  special = false
}

# Store AD bind password in Secrets Manager
resource "aws_secretsmanager_secret" "linotp_ad_bind_password" {
  count = local.environment == "development" ? 1 : 0

  name                    = "${local.application_name}/${local.environment}/linotp-ad-bind-password"
  description             = "LinOTP service account password for AD LDAP queries"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/linotp-ad-bind-password" }
  )
}

resource "aws_secretsmanager_secret_version" "linotp_ad_bind_password" {
  count = local.environment == "development" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.linotp_ad_bind_password[0].id
  secret_string = random_password.linotp_ad_bind_password[0].result

  lifecycle {
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
  description = "LinOTP AD service account setup instructions"
  value = local.environment == "development" ? {
    instructions = "Create the following service account in Active Directory:"
    username     = "linotp-svc"
    ou           = "OU=Service Accounts,DC=laa-workspaces,DC=local"
    bind_dn      = "CN=linotp-svc,OU=Service Accounts,DC=laa-workspaces,DC=local"
    password_cmd = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.linotp_ad_bind_password[0].name} --region eu-west-2 --profile mp-workspaces-dev --query SecretString --output text --no-cli-pager"
    permissions  = "Read access to user objects in the domain (default Domain Users group is sufficient)"
  } : null
}

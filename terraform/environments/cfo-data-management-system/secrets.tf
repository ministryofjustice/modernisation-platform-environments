# RabbitMQ Password
resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "rabbitmq-password" {
  name        = "${local.application_name_short}/${local.environment}/rabbitmq-password"
  description = "RabbitMQ master password for ${local.application_name_short} ${local.environment} environment"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "rabbitmq-password" {
  secret_id     = aws_secretsmanager_secret.rabbitmq-password.id
  secret_string = random_password.rabbitmq.result
}

# App Secrets - Contains third-party credentials and config
# lifecycle ignore_changes to preserve manual updates on subsequent applies.
resource "aws_secretsmanager_secret" "app-secrets" {
  name        = "${local.application_name_short}/${local.environment}/app-secrets"
  description = "Application credentials and configuration for ${local.application_name_short} ${local.environment}"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "app-secrets" {
  secret_id = aws_secretsmanager_secret.app-secrets.id

  # Placeholder values — update manually in the AWS console or via CLI after first apply.
  secret_string = jsonencode({
    Client_ID             = "CHANGE_ME"
    Client_Secret         = "CHANGE_ME"
    API_Client_ID         = "CHANGE_ME"
    Authentication_ApiKey = "CHANGE_ME"
    Sentry_Dsn            = "CHANGE_ME"
    RabbitMQ              = "amqp://user:${random_password.rabbitmq.result}@${aws_instance.rabbitmq.private_dns}:5672"
    CatsRabbitMQ          = "CHANGE_ME"
  })

  lifecycle {
    # Prevent Terraform from overwriting manually updated secret values on subsequent applies
    ignore_changes = [secret_string]
  }
}

# Infra references needed by GitHub Actions deployment workflows
resource "aws_secretsmanager_secret" "deployment" {
  name        = "${local.application_name_short}/${local.environment}/deployment"
  description = "Infrastructure references for GitHub Actions deployment workflows"
  kms_key_id  = data.aws_kms_key.general_shared.arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "deployment" {
  secret_id = aws_secretsmanager_secret.deployment.id
  secret_string = jsonencode({
    ECRRepositoryUrl   = aws_ecr_repository.app.repository_url
    ECSClusterName     = "${local.application_name_short}-${local.environment}-cluster"
    GithubActionsRoleArn = module.github-actions-oidc-role.role
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
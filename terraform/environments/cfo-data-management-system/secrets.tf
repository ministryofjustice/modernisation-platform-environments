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
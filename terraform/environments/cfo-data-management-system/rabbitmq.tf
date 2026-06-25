# AmazonMQ RabbitMQ
resource "aws_mq_broker" "rabbitmq" {
  broker_name = "${local.application_name_short}-${local.environment}-rabbitmq"

  engine_type        = "RABBITMQ"
  engine_version     = "4.2"
  host_instance_type = "mq.m7g.medium"
  auto_minor_version_upgrade = true
  security_groups    = [aws_security_group.rabbitmq.id]
  subnet_ids         = [data.aws_subnet.private_subnets_a.id]

  user {
    username = "user"
    password = aws_secretsmanager_secret_version.rabbitmq-password.secret_string
  }
}
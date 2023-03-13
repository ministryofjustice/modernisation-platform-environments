resource "random_password" "weblogic" {
  length  = 16
  special = false
}


resource "aws_secretsmanager_secret" "weblogic" {
  name = "${local.application_name}/app/weblogic-admin-password"
  description = "This secret has a dynamically generated password. This is OAS administrator (weblogic) password, where developers very frequently use as part of accessing OAS and other admin activities."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/weblogic-admin-password" },
  )
}


resource "aws_secretsmanager_secret_version" "weblogic" {
  secret_id = aws_secretsmanager_secret.weblogic.id
  secret_string = random_password.weblogic.result
}

resource "aws_secretsmanager_secret_rotation" "weblogic" {
  secret_id           = aws_secretsmanager_secret.weblogic.id
  rotation_lambda_arn = module.rotate_secrets_lambda.lambda_arn

  rotation_rules {
    automatically_after_days = 28
  }
}

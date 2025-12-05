resource "random_password" "weblogic" {
  count   = local.environment == "development" ? 1 : 0
  length  = 16
  special = false
}


resource "aws_secretsmanager_secret" "weblogic" {
  count       = local.environment == "development" ? 1 : 0
  name        = "${local.application_name}/app/weblogic-admin-password-tmp2" # TODO This name needs changing back to without -tmp2 to be compatible with hardcoded OAS installation
  description = "This secret has a dynamically generated password. This is OAS administrator (weblogic) password, where developers very frequently use as part of accessing OAS and other admin activities."
  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/app/weblogic-admin-password-tmp2" }, # TODO This name needs changing back to without -tmp2 to be compatible with hardcoded OAS installation
  )
}


resource "aws_secretsmanager_secret_version" "weblogic" {
  count         = local.environment == "development" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.weblogic[0].id
  secret_string = random_password.weblogic[0].result
}

# No password rotation required, therefore commenting it out

# resource "aws_secretsmanager_secret_rotation" "weblogic" {
#   secret_id           = aws_secretsmanager_secret.weblogic.id
#   rotation_lambda_arn = module.rotate_secrets_lambda.lambda_arn
#
#   rotation_rules {
#     automatically_after_days = 28
#   }
# }

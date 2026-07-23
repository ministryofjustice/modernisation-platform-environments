data "aws_secretsmanager_secret_version" "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.elevenlabs_configuration_secret[0].secret_id
}

# data "aws_secretsmanager_secret" "justiceuk_entra" {
#   count = terraform.workspace == "data-platform-development" ? 1 : 0

#   name = "justiceuk/entra"
# }

# data "aws_secretsmanager_secret_version" "justiceuk_entra" {
#   count = terraform.workspace == "data-platform-development" ? 1 : 0

#   secret_id = data.aws_secretsmanager_secret.justiceuk_entra[0].id
# }

# data "aws_iam_openid_connect_provider" "justiceuk_entra" {
#   count = terraform.workspace == "data-platform-development" ? 1 : 0

#   url = "https://sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra[0].secret_string)["tenant_id"]}/"
# }

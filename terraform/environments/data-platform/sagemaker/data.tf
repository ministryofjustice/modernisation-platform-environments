data "aws_secretsmanager_secret_version" "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.elevenlabs_configuration_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "justiceuk_entra_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = "justiceuk/entra"
}

data "aws_iam_openid_connect_provider" "justiceuk_entra" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra_secret[0].secret_string)["tenant_id"]}/"
}

data "aws_secretsmanager_secret_version" "justice_transcribe_backend_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.justice_transcribe_backend_secret[0].secret_id
}

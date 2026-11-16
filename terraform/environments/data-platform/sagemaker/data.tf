data "aws_secretsmanager_secret_version" "elevenlabs_configuration_secret" {
  count = local.is-test ? 0 : 1

  secret_id = module.elevenlabs_configuration_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "justiceuk_entra_secret" {
  count = local.is-test ? 0 : 1

  secret_id = "justiceuk/entra"
}

data "aws_iam_openid_connect_provider" "justiceuk_entra" {
  count = local.is-test ? 0 : 1

  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/sts.windows.net/${jsondecode(data.aws_secretsmanager_secret_version.justiceuk_entra_secret[0].secret_string)["tenant_id"]}/"
}

data "aws_secretsmanager_secret_version" "justice_transcribe_backend_secret" {
  count = local.is-test ? 0 : 1

  secret_id = module.justice_transcribe_backend_secret[0].secret_id
}

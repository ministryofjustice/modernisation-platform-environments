data "aws_secretsmanager_secret_version" "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.elevenlabs_configuration_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "justiceai_entra_application_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.justiceai_entra_application_secret[0].secret_id
}

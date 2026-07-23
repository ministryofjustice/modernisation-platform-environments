data "aws_secretsmanager_secret_version" "elevenlabs_configuration_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.elevenlabs_configuration_secret[0].secret_id
}

data "aws_secretsmanager_secret_version" "justice_transcribe_backend_secret" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.justice_transcribe_backend_secret[0].secret_id
}

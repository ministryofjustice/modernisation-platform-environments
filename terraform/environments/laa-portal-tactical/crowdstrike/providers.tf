provider "crowdstrike" {
  client_id     = jsondecode(data.aws_secretsmanager_secret_version.crowdstrike.secret_string).client_id
  client_secret = jsondecode(data.aws_secretsmanager_secret_version.crowdstrike.secret_string).client_secret
}

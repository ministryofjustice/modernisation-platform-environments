resource "aws_secretsmanager_secret" "crowdstrike" {
  #checkov:skip=CKV2_AWS_57
  #checkov:skip=CKV_AWS_149
  name_prefix = "falcon_client_secret"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "crowdstrike" {
  lifecycle { ignore_changes = [secret_string] }
  secret_id = aws_secretsmanager_secret.crowdstrike.id
  secret_string = jsonencode({
    client_id     = ""
    client_secret = ""
  })
}

# Data call needs to be created to pass credentials into provider block
data "aws_secretsmanager_secret_version" "crowdstrike" {
  secret_id = aws_secretsmanager_secret.crowdstrike.id
}

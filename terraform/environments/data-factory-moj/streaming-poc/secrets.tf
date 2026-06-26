# ---------------------------------------------------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "gitlab_token" {
  count = contains(local.deploy_to, local.environment) ? 1 : 0

  name        = "/streaming-poc/${local.environment}/gitlab-token"
  description = "GitLab token used by the SDG container"

  tags = local.extended_tags
}

resource "aws_secretsmanager_secret_version" "gitlab_token" {
  count = contains(local.deploy_to, local.environment) ? 1 : 0

  secret_id     = aws_secretsmanager_secret.gitlab_token[0].id
  secret_string = "dummy-gitlab-token"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

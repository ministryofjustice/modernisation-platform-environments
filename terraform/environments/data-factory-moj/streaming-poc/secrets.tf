# ---------------------------------------------------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "gitlab_token" {
  #checkov:skip=CKV2_AWS_57: GitLab token is managed manually in the console and must not be rotated by Terraform.
  count = contains(local.deploy_to, local.environment) ? 1 : 0

  name        = "/streaming-poc/${local.environment}/gitlab-token"
  description = "GitLab token used by the SDG container"
  kms_key_id  = aws_kms_key.secretsmanager[0].arn

  tags = local.extended_tags
}

resource "aws_secretsmanager_secret_version" "gitlab_token" {
  #checkov:skip=CKV_SECRET_6: Secret string is a placeholder only
  count = contains(local.deploy_to, local.environment) ? 1 : 0

  secret_id     = aws_secretsmanager_secret.gitlab_token[0].id
  secret_string = "not-a-real-secret"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

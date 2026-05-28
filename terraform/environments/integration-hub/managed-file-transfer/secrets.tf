module "secrets_transfer_user_ssh" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.application_name}-transfer-user-ssh-keys"
  description             = "${local.application_name} Transfer User SSH Keys"
  recovery_window_in_days = 7
  kms_key_id              = module.kms_secrets.key_arn
  create_policy           = true
  block_public_policy     = true
  ignore_secret_changes   = true

  policy_statements = {
    read = {
      sid = "AllowCIRolesToRead"
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
        ]
      }]
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = ["*"]
    }
  }
  # This value will be manually populated in AWS and will be ignored due to ignore_secret_changes = true
  secret_string = jsonencode({
    username = "123456789012"
  })
}

data "aws_secretsmanager_secret_version" "secrets_transfer_user_ssh" {
  depends_on = [module.secrets_transfer_user_ssh]
  secret_id  = module.secrets_transfer_user_ssh.secret_id
}
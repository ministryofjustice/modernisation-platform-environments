module "secrets_transfer_user_ssh_keys" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.0.0"

  name                    = "transfer-user-ssh-keys"
  description             = "Transfer user SSH keys"
  recovery_window_in_days = 7
  kms_key_id              = module.kms_secrets.key_id
  create_policy           = true
  block_public_policy     = true
  ignore_secret_changes   = true

  policy_statements = {
    read = {
      sid = "AllowCIRolesToRead"
      principals = [{
        type = "AWS"
        identifiers = [
          for role_name in toset([
            var.collaborator_access,
            "MemberInfrastructureAccess",
          ]) :
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role_name}"
        ]
      }]
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = ["*"]
    }
  }
  # This value is manually maintained in AWS and ignored after creation.
  # {
  #   "random-pet-name": {
  #     "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample transfer-user"
  #   }
  # }
  secret_string = jsonencode({

  })
}

data "aws_secretsmanager_secret_version" "secrets_transfer_user_ssh_keys" {
  secret_id = module.secrets_transfer_user_ssh_keys.secret_id

}
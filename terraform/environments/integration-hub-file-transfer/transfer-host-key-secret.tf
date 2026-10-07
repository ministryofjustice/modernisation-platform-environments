# Holds the SFTP server's SSH host key so it survives a Transfer server
# rebuild. AWS-generated host keys cannot be exported, so importing our own
# key here means Terraform can re-attach the same key (and fingerprint) to a
# replacement server. The aws_transfer_host_key resource that consumes this
# secret follows in a later change.
#
# Terraform only ever writes the placeholder below. Populate the real
# PEM-encoded private key directly in Secrets Manager once this has been
# applied; ignore_secret_changes means Terraform will never overwrite it.
module "secrets_transfer_host_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  name                    = "${local.application_name}/${local.environment}/transfer-host-key"
  description             = "SSH host key for the ${local.application_name} Transfer Family server"
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

  secret_string = "placeholder"
}

# Reads back whatever value is currently in the secret. The host key
# resource added in a later change will consume this.
data "aws_secretsmanager_secret_version" "transfer_host_key" {
  secret_id = module.secrets_transfer_host_key.secret_id

  depends_on = [module.secrets_transfer_host_key]
}

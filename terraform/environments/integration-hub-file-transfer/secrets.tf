module "secrets_file_dispatch_prefix" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = merge(local.environment_file_dispatch_prefixes...)

  name                    = each.key
  description             = "File dispatch configuration for the ${trimprefix(each.key, local.file_dispatch_secret_name_prefix)} object key prefix"
  recovery_window_in_days = 0
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

  secret_string = jsonencode(each.value)
}

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

  secret_string = <<-EOT
    -----BEGIN OPENSSH PRIVATE KEY-----
    PLACEHOLDER-REPLACE-WITH-REAL-HOST-KEY-PEM-CONTENT
    -----END OPENSSH PRIVATE KEY-----
  EOT
}

data "aws_secretsmanager_secret_version" "transfer_host_key" {
  secret_id = module.secrets_transfer_host_key.secret_id

  depends_on = [module.secrets_transfer_host_key]
}

ephemeral "tls_private_key" "sftp_client" {
  for_each = local.push_to_sftp_entries

  algorithm = "ED25519"
}

module "secrets_private_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = local.push_to_sftp_entries

  name                    = "${local.sftp_key_secret_prefix}/${each.value.name_suffix}/private"
  description             = "SSH client private key JSON for ${each.value.name_suffix}"
  kms_key_id              = module.kms_credentials.key_arn
  recovery_window_in_days = 30

  create_secret_version    = true
  create_random_password   = false
  ignore_secret_changes    = true
  secret_string_wo_version = "1"
  secret_string_wo = jsonencode({
    private_key = ephemeral.tls_private_key.sftp_client[each.key].private_key_openssh
  })

  tags = local.tags
}

module "secrets_public_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = local.push_to_sftp_entries

  name                    = "${local.sftp_key_secret_prefix}/${each.value.name_suffix}/public"
  description             = "OpenSSH client public key for ${each.value.name_suffix}"
  kms_key_id              = module.kms_credentials.key_arn
  recovery_window_in_days = 30

  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read_public_key_developer = {
      sid    = "AllowModernisationPlatformDeveloperRead"
      effect = "Allow"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
      resources = ["*"]
      condition = [
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values   = [local.modernisation_platform_developer_role_arn_pattern]
        },
        {
          test     = "Bool"
          variable = "aws:SecureTransport"
          values   = ["true"]
        },
      ]
    }
  }

  create_secret_version    = true
  create_random_password   = false
  ignore_secret_changes    = true
  secret_string_wo_version = "1"
  secret_string_wo         = trimspace(ephemeral.tls_private_key.sftp_client[each.key].public_key_openssh)

  tags = local.tags
}
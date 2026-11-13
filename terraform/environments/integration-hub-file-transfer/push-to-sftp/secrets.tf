import {
  for_each = terraform.workspace == "integration-hub-file-transfer-test" ? {
    "test-harness/push-to-sftp/" = "private-key-BgTxYa"
  } : {}

  to = module.secrets_private_key[each.key].aws_secretsmanager_secret.this[0]
  id = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:integration-hub-file-transfer/push-to-sftp/test-harness-push-to-sftp/${each.value}"
}

module "secrets_private_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = local.push_to_sftp_entries

  name                    = "${local.application_name}/push-to-sftp/${each.value.name_suffix}/private-key"
  description             = "Operator-populated SSH private key JSON for ${each.value.name_suffix}"
  kms_key_id              = module.kms_credentials.key_arn
  recovery_window_in_days = 30

  create_secret_version  = false
  create_random_password = false

  tags = local.tags
}

import {
  for_each = terraform.workspace == "integration-hub-file-transfer-test" ? {
    "test-harness/push-to-sftp/" = "public-key-2j5Qja"
  } : {}

  to = module.secrets_public_key[each.key].aws_secretsmanager_secret.this[0]
  id = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:integration-hub-file-transfer/push-to-sftp/test-harness-push-to-sftp/${each.value}"
}

module "secrets_public_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  for_each = local.push_to_sftp_entries

  name                    = "${local.application_name}/push-to-sftp/${each.value.name_suffix}/public-key"
  description             = "Operator-populated OpenSSH client public key for ${each.value.name_suffix}"
  kms_key_id              = module.kms_credentials.key_arn
  recovery_window_in_days = 30

  create_secret_version  = false
  create_random_password = false

  tags = local.tags
}
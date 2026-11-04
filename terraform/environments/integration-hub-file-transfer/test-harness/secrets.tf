data "aws_kms_alias" "secrets" {
  count = local.create_test_harness ? 1 : 0

  name = local.secrets_kms_key_alias
}

# Container only. The operator stores the private host key out of band, never through Terraform.
module "secrets_sftp_host_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  create = local.create_test_harness

  name                    = local.sftp_host_key_secret_name
  description             = "Operator-populated private host key for the test SFTP server"
  kms_key_id              = local.create_test_harness ? data.aws_kms_alias.secrets[0].target_key_arn : null
  recovery_window_in_days = 30

  create_secret_version  = false
  create_random_password = false

  tags = local.tags
}

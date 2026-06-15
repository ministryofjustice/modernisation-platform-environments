module "data_platform_app_secrets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "data-platform-test" ? 0 : 1

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name       = "data-platform-app/app-secrets"
  kms_key_id = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string = jsonencode({
    secret_key          = random_password.dashboard_service_secret_key[0].result,
  })
  ignore_secret_changes = true

  tags = local.tags
}

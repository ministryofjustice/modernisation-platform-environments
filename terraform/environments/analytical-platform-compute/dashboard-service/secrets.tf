module "dashboard_service_app_secrets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name       = "dashboard-service/app-secrets"
  kms_key_id = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string = jsonencode({
    secret_key          = random_password.dashboard_service_secret_key[0].result,
    sentry_dsn          = "CHANGEME",
    auth0_client_id     = "CHANGEME",
    auth0_client_secret = "CHANGEME",
  })
  ignore_secret_changes = true

  tags = local.tags
}

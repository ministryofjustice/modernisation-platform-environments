module "actions_runners_token_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "actions-runners/token/apc-self-hosted-runners"
  description = "moj-data-platform-robot: https://github.com/settings/personal-access-tokens/4282353"
  kms_key_id  = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      "expiry-date" = "2025-10-23"
    }
  )
}

module "actions_runners_token_moj_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "actions-runners/token/moj-apc-self-hosted-runners"
  description = "moj-data-platform-robot: https://github.com/settings/personal-access-tokens/5605162"
  # kms_key_id  = data.common_secrets_manager_kms.key_arn
  kms_key_id = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string         = "CHANGEME"
  ignore_secret_changes = true

  tags = merge(
    local.tags,
    {
      "expiry-date" = "2025-10-23"
    }
  )
}

module "actions_runners_github_app_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "actions-runners/app/apc-self-hosted-runners"
  description = "https://github.com/organizations/moj-analytical-services/settings/apps/analytical-platform-runners"
  kms_key_id  = data.aws_kms_key.common_secrets_manager_kms.arn

  secret_string = jsonencode({
    app_id          = "CHANGEME",
    client_id       = "CHANGEME",
    installation_id = "CHANGEME",
    private_key     = "CHANGEME"
  })
  ignore_secret_changes = true

  tags = local.tags
}

# =============================================================================
# USED BY: ALL runners - moj-analytical-services (21) AND data-catalogue.
# GitHub App analytical-platform-runners - KEDA SCALING only (not registration).
#   private_key            -> kubernetes_manifest.actions_runners_github_app_apc_self_hosted_runners_secret
#   app_id/installation_id -> data.aws_secretsmanager_secret_version... -> helm values (KEDA trigger)
# =============================================================================
module "actions_runners_github_app_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

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

# =============================================================================
# USED BY: moj-analytical-services runners ONLY (21 runners).
# GitHub App (moj-analytical-services org) - runner REGISTRATION. Replaces PAT 4282353.
# Installed on: airflow, airflow-create-a-pipeline, create-a-derived-table.
# Permissions (set on the App): Repository -> Administration: Read & write.
# Values set manually in Secrets Manager (private_key = PEM, base64-encoded).
# =============================================================================
module "actions_runners_github_app_mojas_registration_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name        = "actions-runners/app/mojas-registration-apc-self-hosted-runners"
  description = "GitHub App (moj-analytical-services org) - runner registration (Administration: RW)"
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

# =============================================================================
# USED BY: data-catalogue runner ONLY.
# GitHub App (ministryofjustice org) - runner REGISTRATION. Replaces PAT 5605162.
# Installed on: data-catalogue.
# Permissions (set on the App): Repository -> Administration: Read & write.
# Values set manually in Secrets Manager (private_key = PEM, base64-encoded).
# =============================================================================
module "actions_runners_github_app_moj_registration_secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name        = "actions-runners/app/moj-registration-apc-self-hosted-runners"
  description = "GitHub App (ministryofjustice org) - data-catalogue runner registration (Administration: RW)"
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
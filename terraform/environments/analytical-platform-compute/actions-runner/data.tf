# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}

# EKS
data "aws_eks_cluster" "apc_cluster" {
  name = local.eks_cluster_name
}

data "aws_eks_cluster_auth" "apc_cluster" {
  name = data.aws_eks_cluster.apc_cluster.name
}

# Secrets Manager
# =============================================================================
# USED BY: ALL runners - moj-analytical-services (21) AND data-catalogue.
# KEDA App IDs -> helm values -> KEDA trigger (SCALING).
# =============================================================================
data "aws_secretsmanager_secret_version" "actions_runners_github_app_apc_self_hosted_runners_secret" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
}

# =============================================================================
# USED BY: moj-analytical-services runners ONLY.
# Registration App IDs (app_id / installation_id) for actions_runners_mojas_registration_token_generator.
# Read at plan time: re-run terraform after changing values in Secrets Manager.
# =============================================================================
data "aws_secretsmanager_secret_version" "actions_runners_github_app_mojas_registration_secret" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_github_app_mojas_registration_secret[0].secret_id
}

# =============================================================================
# USED BY: data-catalogue runner ONLY.
# Registration App IDs (app_id / installation_id) for actions_runners_moj_registration_token_generator.
# Read at plan time: re-run terraform after changing values in Secrets Manager.
# =============================================================================
data "aws_secretsmanager_secret_version" "actions_runners_github_app_moj_registration_secret" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_github_app_moj_registration_secret[0].secret_id
}
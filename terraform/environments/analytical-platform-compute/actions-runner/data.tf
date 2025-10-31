# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}

# EKS
data "aws_eks_cluster" "apc_cluster" {
  name = local.eks_cluster_name
}

# Secrets Manager
data "aws_secretsmanager_secret_version" "actions_runners_github_app_apc_self_hosted_runners_secret" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
}

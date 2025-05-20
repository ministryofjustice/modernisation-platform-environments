data "aws_secretsmanager_secret_version" "actions_runners_token_apc_self_hosted_runners_github_app" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_token_apc_self_hosted_runners_github_app[0].secret_id
}

# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}

# Kubernetes
# data "kubernetes_namespace" "actions_runners" {
#   metadata {
#     name = "actions-runners"
#   }
# }

data "kubernetes_namespace" "actions_runners" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name = "actions-runners"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "baseline"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "actions-runners"
    }
  }
}

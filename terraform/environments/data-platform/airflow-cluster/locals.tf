locals {
  # Kept only so the Kubernetes/Helm providers can reach the cluster while
  # Terraform destroys everything still recorded in state.
  eks_cluster_name = "${local.application_name}-${local.environment}-airflow"
}

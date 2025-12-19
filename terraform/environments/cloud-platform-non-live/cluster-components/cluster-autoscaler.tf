module "cluster_autoscaler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=1.34-upgrade"

  enable_overprovision        = local.environment_configuration.autoscaler.enable_overprovision
  cluster_domain_name         = replace(data.aws_eks_cluster.cluster.endpoint, "https://", "")
  eks_cluster_id              = data.aws_eks_cluster.cluster.id
  eks_cluster_oidc_issuer_url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  enable_vpa_recommender      = local.environment_configuration.autoscaler.enable_vpa_recommender
  role-name                   = local.environment

  # These values are for tuning live cluster overprovisioner memory and CPU requests
  live_memory_request = "1800Mi"
  live_cpu_request    = "200m"

  # depends_on = [
  #   module.label_pods_controller,
  #   module.monitoring
  # ]
}
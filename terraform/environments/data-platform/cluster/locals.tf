locals {
  environment_configuration = local.environment_configurations[local.environment]
  cluster_configuration     = yamldecode(file("${path.module}/configuration/cluster.yml"))["environment"][local.environment]

  eks_cluster_name                    = "${local.application_name}-${local.environment}"
  eks_cluster_logs_log_group_name     = "/aws/eks/${local.eks_cluster_name}/cluster"
  eks_application_logs_log_group_name = "/aws/eks/${local.eks_cluster_name}/application"

  aps_log_group_name = "/aws/aps/${local.eks_cluster_name}"

  container_insights_log_group_name = "/aws/containerinsights/${local.eks_cluster_name}/performance"

  kyverno_privileged_policies = [
    {
      name        = "cloudwatch-agent"
      description = "The CloudWatch agent DaemonSet requires elevated capabilities to collect host-level metrics and kernel performance data."
      namespaces  = [module.aws_cloudwatch_observability_namespace.name]
      pod_selector_labels = {
        "app.kubernetes.io/name" = "cloudwatch-agent"
      }
      capabilities_add = [
        "SYS_PTRACE",
        "DAC_READ_SEARCH",
        "SYS_RESOURCE",
      ]
    },
    # ── Template: add further services below ──────────────────────────────────
    # {
    #   name        = "my-service"
    #   description = "Short justification for why capabilities are needed."
    #   namespaces  = ["my-namespace"]
    #   pod_selector_labels = {
    #     "app.kubernetes.io/name" = "my-service"
    #   }
    #   capabilities_add = [
    #     "SYS_PTRACE",
    #   ]
    # },
    # ─────────────────────────────────────────────────────────────────────────
  ]
}

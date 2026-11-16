resource "aws_networkflowmonitor_monitor" "eks" {
  monitor_name = "${module.eks.cluster_name}-eks-monitor"
  scope_arn    = data.aws_ssm_parameter.network_monitor_scope_arn.value

  local_resource {
    type       = "AWS::EKS::Cluster"
    identifier = module.eks.cluster_arn
  }
}

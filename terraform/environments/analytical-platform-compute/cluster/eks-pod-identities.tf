/*
  This EKS Pod Identity is unused as the aws-cloudwatch-metrics Helm chart doesn't support IRSA or EKS Pod Identity
  Instead it is configured to use hostNetwork to consume the EKS node role
*/
module "aws_cloudwatch_metrics_pod_identity" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

  name = "aws-cloudwatch-metrics"

  additional_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  associations = {
    eks = {
      cluster_name    = module.eks.cluster_name
      namespace       = kubernetes_namespace.aws_observability.metadata[0].name
      service_account = "aws-cloudwatch-metrics"
    }
  }

  tags = local.tags
}

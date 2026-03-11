module "aws_cloudwatch_observability_eks_pod_identity" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity.git?ref=776d089cf8b13dbff25e32e78272f8f693f5cb29" # v2.7.0

  name = "aws-cloudwatch-observability"

  attach_aws_cloudwatch_observability_policy = true

  associations = {
    cluster = {
      cluster_name    = module.eks.cluster_name
      namespace       = module.aws_cloudwatch_observability_namespace.name
      service_account = "cloudwatch-agent"
    }
  }
}

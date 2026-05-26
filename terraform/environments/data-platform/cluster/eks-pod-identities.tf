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


module "aws_load_balancer_controller_eks_pod_identity" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks-pod-identity.git?ref=776d089cf8b13dbff25e32e78272f8f693f5cb29" # v2.7.0

  name = "aws-load-balancer-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller-sa"
    }
  }
}

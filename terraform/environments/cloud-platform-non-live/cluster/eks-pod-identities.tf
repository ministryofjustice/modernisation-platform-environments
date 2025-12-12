module "aws_vpc_cni_pod_identity" {

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

  name = "aws-vpc-cni"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  associations = {
    this = {
      cluster_name    = module.eks[0].cluster_name
      namespace       = "kube-system"
      service_account = "aws-node"
    }
  }

  tags = local.tags
}
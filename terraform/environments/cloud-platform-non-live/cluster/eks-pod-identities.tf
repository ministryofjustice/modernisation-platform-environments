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

module "aws_ebs_csi_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  # aws_ebs_csi_kms_arns      = ["arn:aws:kms:*:*:key/1234abcd-12ab-34cd-56ef-1234567890ab"]

  associations = {
    this = {
      cluster_name    = module.eks[0].cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = local.tags
}
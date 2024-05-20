module "aws_cloudwatch_metrics_pod_identity" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "1.2.0"

  name = "aws-cloudwatch-metrics"

  additional_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  associations = {
    eks = {
      cluster_name    = module.eks.cluster_name
      namespace       = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
      service_account = "aws-cloudwatch-metrics"
    }
  }

  tags = local.tags
}

module "aws_for_fluent_bit_pod_identity" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "1.2.0"

  name = "aws-for-fluent-bit"

  policy_statements = [
    {
      sid = "AllowKMS"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = [module.eks_cluster_logs_kms.key_arn]
    }
  ]

  additional_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  associations = {
    eks = {
      cluster_name    = module.eks.cluster_name
      namespace       = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
      service_account = "aws-cloudwatch-metrics"
    }
  }

  tags = local.tags
}

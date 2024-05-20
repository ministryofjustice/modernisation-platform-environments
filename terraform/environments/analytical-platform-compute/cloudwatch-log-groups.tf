module "eks_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.3.1"

  name       = "/aws/eks/${local.our_vpc_name}/logs"
  kms_key_id = module.eks_cluster_logs_kms.key_arn
  retention_in_days = 400

  tags = local.tags
}

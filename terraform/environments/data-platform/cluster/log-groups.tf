module "eks_cluster_logs_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=a2a5f9d15e30d0d24b667933599e5e1bef24a8b8" # v5.7.2

  name              = local.eks_cluster_logs_log_group_name
  kms_key_id        = module.eks_logs_kms_key.key_arn
  retention_in_days = 365
}

module "eks_application_logs_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=a2a5f9d15e30d0d24b667933599e5e1bef24a8b8" # v5.7.2

  name              = local.eks_application_logs_log_group_name
  kms_key_id        = module.eks_logs_kms_key.key_arn
  retention_in_days = 365
}

module "prometheus" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-managed-service-prometheus.git?ref=93946d1d124aad009802878e7e02c4dcf00f093f" # v4.3.1

  workspace_alias = local.eks_cluster_name
  kms_key_arn     = module.prometheus_kms_key.key_arn

  logging_configuration = {
    create_log_group = false
    log_group_arn = "${module.prometheus_log_group.cloudwatch_log_group_arn}:*"
  }
}


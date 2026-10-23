module "prometheus" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-managed-service-prometheus.git?ref=93946d1d124aad009802878e7e02c4dcf00f093f" # v4.3.1

  workspace_alias = local.eks_cluster_name
  kms_key_arn     = module.prometheus_kms_key.key_arn

  #   retention_period_in_days = 365 # Defaults to 150 days, but this setting is linked to `limits_per_label_set` and I don't think we want that. If we want to set this, we need to use a separate aws_prometheus_workspace_configuration resource

  logging_configuration = {
    create_log_group = false
    log_group_arn    = "${module.prometheus_log_group.cloudwatch_log_group_arn}:*"
  }
}

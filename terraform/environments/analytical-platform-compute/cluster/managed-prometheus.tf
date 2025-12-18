module "managed_prometheus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "4.2.1"

  workspace_alias = local.amp_workspace_alias
  kms_key_arn     = module.managed_prometheus_kms.key_arn
  logging_configuration = {
    log_group_arn = "${module.managed_prometheus_log_group.cloudwatch_log_group_arn}:*"
  }

  # Workaround for https://github.com/terraform-aws-modules/terraform-aws-managed-service-prometheus/issues/33
  # Setting retention_period_in_days prevents "Empty workspace configuration" API error
  retention_period_in_days = 150

  tags = local.tags
}

moved {
  from = aws_prometheus_workspace.main
  to   = module.managed_prometheus.aws_prometheus_workspace.this[0]
}

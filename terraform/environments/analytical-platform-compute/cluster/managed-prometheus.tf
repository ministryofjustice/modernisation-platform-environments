module "managed_prometheus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "4.2.0"

  workspace_alias = local.amp_workspace_alias
  kms_key_arn     = module.managed_prometheus_kms.key_arn
  logging_configuration = {
    log_group_arn = "${module.managed_prometheus_log_group.cloudwatch_log_group_arn}:*"
  }

  tags = local.tags
}

moved {
  from = aws_prometheus_workspace.main
  to   = module.managed_prometheus.aws_prometheus_workspace.this[0]
}

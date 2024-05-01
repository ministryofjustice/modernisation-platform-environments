module "vpc_flow_logs_log_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.3.1"

  name              = "/aws/vpc/flow-log"
  kms_key_id        = module.vpc_flow_logs_kms.key_arn
  retention_in_days = 400

  tags = local.tags
}

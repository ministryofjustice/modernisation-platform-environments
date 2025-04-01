module "transfer_server_structured_logs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.0"

  name              = "/aws/transfer-server-structured-logs"
  kms_key_id        = module.transfer_server_logs_kms.key_arn
  retention_in_days = 400
}

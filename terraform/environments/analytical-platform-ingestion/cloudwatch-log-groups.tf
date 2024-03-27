module "transfer_structured_logs" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.3.1"

  name              = "/aws/transfer-structured-logs"
  kms_key_id        = module.transfer_logs_kms.key_id
  retention_in_days = 400
}

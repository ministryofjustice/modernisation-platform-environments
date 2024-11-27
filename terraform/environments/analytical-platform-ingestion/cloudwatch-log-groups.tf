module "transfer_structured_logs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.0"

  name              = "/aws/transfer-structured-logs"
  kms_key_id        = module.transfer_logs_kms.key_arn
  retention_in_days = 400
}

module "connected_vpc_route53_resolver_logs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.0"

  name              = "/aws/route53-resolver/connected-vpc"
  retention_in_days = 400
}

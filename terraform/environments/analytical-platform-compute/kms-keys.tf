module "vpc_flow_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases                 = ["vpc/flow-logs"]
  description             = "VPC flow logs KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7

  tags = local.tags
}

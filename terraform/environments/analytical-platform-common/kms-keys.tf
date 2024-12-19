module "ecr_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["ecr/default"]
  description           = "ECR default KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

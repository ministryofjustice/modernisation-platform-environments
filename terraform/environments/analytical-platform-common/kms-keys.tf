module "ecr_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["ecr/default"]
  description           = "ECR default KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "terraform_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["s3/terraform"]
  description           = "S3 Terraform KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "secrets_manager_common_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["secretsmanager/common"]
  description           = "Secrets Manager Common KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

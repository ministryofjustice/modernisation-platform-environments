# COAT GitHub repositories KMS for Terraform state bucket
module "coat_github_repos_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/coat-github-repos"]
  description           = "S3 COAT github repos terraform KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
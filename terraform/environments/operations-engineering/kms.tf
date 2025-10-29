module "cur_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/cur"]
  description           = "S3 CUR KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "gpx_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/gpx"]
  description           = "S3 gpx KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "github_repos_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/github-repos"]
  description           = "S3 github repos terraform KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "auth0_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/auth0"]
  description           = "S3 auth0 terraform KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "datahub_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["rds/datahub"]
  description           = "Datahub RDS"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "datahub_opensearch_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["opensearch/datahub"]
  description           = "Open Metadata OpenSearch"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

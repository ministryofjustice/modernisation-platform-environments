module "mlflow_auth_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["rds/mlflow-auth"]
  description           = "MLflow Auth RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "mlflow_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["rds/mlflow"]
  description           = "MLflow RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "mlflow_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["s3/mlflow"]
  description           = "MLflow S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

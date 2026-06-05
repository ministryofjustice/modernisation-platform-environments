module "mlflow_auth_rds_kms" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0


  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["rds/mlflow-auth"]
  description           = "MLflow Auth RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "mlflow_rds_kms" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0


  aliases               = ["rds/mlflow"]
  description           = "MLflow RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "mlflow_s3_kms" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["s3/mlflow"]
  description           = "MLflow S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

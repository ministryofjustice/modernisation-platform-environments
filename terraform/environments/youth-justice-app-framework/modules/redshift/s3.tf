module "s3" {
  source = "../s3"

  environment_name = var.environment_name

  transfer_bucket_name = ["redshift-yjb-reporting"]

  project_name = var.project_name

  tags = var.tags

}

locals {
  s3-redshift-yjb-reporting-arn = module.s3.aws_s3_bucket_arn[0]
}
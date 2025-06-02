module "s3" {
  source = "../s3"

  project_name = var.project_name
  environment  = var.environment

  transfer_bucket_name = ["redshift-yjb-reporting", "redshift-ycs-reporting"]

  tags = var.tags

}

locals {
  s3-redshift-yjb-reporting-arn = module.s3.aws_s3_bucket_arn[0]
  s3-redshift-ycs-reporting-arn = module.s3.aws_s3_bucket_arn[1]
}
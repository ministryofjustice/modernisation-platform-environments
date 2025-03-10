module "s3" {
  source = "../s3"

  environment_name = "${var.project_name}-${var.environment}"

  bucket_name = [local.alb_access_logs_bucket_name_suffix]

  project_name = var.project_name

  tags = var.tags

}


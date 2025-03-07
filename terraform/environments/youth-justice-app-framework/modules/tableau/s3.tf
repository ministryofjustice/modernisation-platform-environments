module "s3" {
  source = "../s3"

  environment_name = "${var.project_name}-${var.environment}"

  bucket_name = ["tableau-alb-logs"]

  project_name = var.project_name

  tags = var.tags

}

locals {
  tableau_alb_logs_arn = module.s3.aws_s3_bucket_arn[0]
}
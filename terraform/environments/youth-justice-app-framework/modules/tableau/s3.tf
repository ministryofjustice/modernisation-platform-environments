module "log_bucket" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.2"

  bucket = "${var.project_name}-${var.environment}-${local.alb_access_logs_bucket_name_suffix}"
  acl    = "log-delivery-write"

  # For example only
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = false #todo probably should be true but matching yjaf atm
  attach_require_latest_tls_policy      = false #todo same here
  #todo cloudtrail dataevents for this bucket required
  tags = local.all_tags
}


## s3 bucket for Tableau backups
module "s3" {
  source = "../s3"

  project_name = var.project_name
  environment  = var.environment

  bucket_name = [local.tableau-backups-bucket-name]

  tags = var.tags

}

locals {
  s3_tableau_backup = module.s3.aws_s3_bucket[local.tableau-backups-bucket-name].arn
}

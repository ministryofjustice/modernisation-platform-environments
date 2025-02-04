module "s3_staging" {
  source = "./modules/cal_centre_staging"
  bucket_name = "call-centre-staging"
  lifecycle_rule_enabled = true
  versioning_status      = "Enabled"
}
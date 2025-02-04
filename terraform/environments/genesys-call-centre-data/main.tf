module "s3_staging" {
  source = "./modules/call_centre_staging"
  bucket_name = "call-centre-staging"
}
module "test_s3_bucket" {
  source        = "./modules/test"
  bucket_prefix = "root-"
  tags = {
    Environment = "root"
    Component   = "sprinkler"
  }
}

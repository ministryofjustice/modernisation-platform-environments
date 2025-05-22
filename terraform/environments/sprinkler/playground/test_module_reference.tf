module "test_s3_bucket" {
  source        = "../modules/test"
  bucket_prefix = "playground-"
  tags = {
    Environment = "playground"
    Component   = "sprinkler"
  }
}

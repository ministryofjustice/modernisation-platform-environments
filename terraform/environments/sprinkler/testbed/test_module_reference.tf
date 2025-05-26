module "test_s3_bucket" {
  source        = "../modules/test"
  bucket_prefix = "testbed-"
  tags = {
    Environment = "testbed"
    Component   = "sprinkler"
  }
}

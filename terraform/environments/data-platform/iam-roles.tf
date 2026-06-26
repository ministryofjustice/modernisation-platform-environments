module "monitoring" {
  source = "./modules/monitoring"
}

resource "aws_s3_bucket" "test" {
  bucket = "test-runner-modernisation-platform"
}
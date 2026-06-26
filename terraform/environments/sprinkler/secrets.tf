#### This file can be used to store secrets specific to the member account ####
resource "aws_s3_bucket" "test" {
  bucket = "test-runner-modernisation-platform"
}
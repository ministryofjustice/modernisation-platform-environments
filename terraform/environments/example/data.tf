#### This file can be used to store data specific to the member account ####

# For macie code
data "aws_s3_bucket" "bucket1" {
  bucket = module.bastion_linux.bastion_s3_bucket.bucket.id
}

data "aws_s3_bucket" "bucket2" {
  bucket = "config-20220505080423816000000003"
}

data "aws_s3_bucket" "bucket3" {
  bucket = module.s3-bucket.bucket.id
}
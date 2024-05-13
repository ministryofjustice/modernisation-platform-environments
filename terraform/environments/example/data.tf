#### This file can be used to store data specific to the member account ####

# For macie code
 data "aws_s3_bucket" "bucket1" {
   bucket = "bastion-example-example-development-jxaebg"
 }

 data "aws_s3_bucket" "bucket2" {
   bucket = "config-20220505080423816000000003"
 }
 
 data "aws_s3_bucket" "bucket3" {
   bucket = "s3-bucket-example20240430100555519600000006"
 }
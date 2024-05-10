#### This file can be used to store data specific to the member account ####

# For macie code
 data "aws_s3_bucket" "bucket1" {
   bucket = "config-20220407082146408700000002"
 }

 data "aws_s3_bucket" "bucket2" {
   bucket = "aws-sam-cli-managed-default-samclisourcebucket-1leowh6voenwy"
 }
 
 data "aws_s3_bucket" "bucket3" {
   bucket = "macie-test-results-cooker"
 }
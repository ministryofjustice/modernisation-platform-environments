# Shared S3 artifact references for Lambda functions

# Provider Load Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "provider_load_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/provider_load_package.zip"
}

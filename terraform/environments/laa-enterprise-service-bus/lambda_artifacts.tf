# Shared S3 artifact references for Lambda functions

data "aws_s3_bucket" "lambda_files" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
}

# CWA Extract Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "cwa_extract_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/cwa_extract_package.zip"
}

# CWA File Transfer Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "cwa_file_transfer_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/cwa_file_transfer_package.zip"
}

# CWA SNS Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "cwa_sns_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/cwa_sns_lambda.zip"
}

# Provider Load Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "provider_load_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/provider_load_package.zip"
}

# Purge Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "purge_lambda_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/purge_lambda_package.zip"
}

# Cloudwatch Alarm Lambda package stored in the shared lambda-files bucket
# Ensure this object exists and the bucket has versioning enabled so updates are tracked via version_id
data "aws_s3_object" "cloudwatch_log_alert_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/cloudwatch_log_alert.zip"
}

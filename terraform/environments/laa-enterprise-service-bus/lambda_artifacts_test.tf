data "aws_s3_object" "test_cwa_extract_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/test_cwa_extract_package.zip"
}

data "aws_s3_object" "test_provider_load_zip" {
  bucket = "${local.application_name_short}-${local.environment}-lambda-files"
  key    = "lambda_files/test_provider_load_package.zip"
}

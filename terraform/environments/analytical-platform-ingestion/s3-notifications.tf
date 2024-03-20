module "ingestion_landing" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "4.1.0"

  bucket = module.landing_bucket.s3_bucket_id

  lambda_notifications = {
    ingestion_scan = {
      function_name = module.scan_lambda.lambda_function_name
      function_arn  = module.scan_lambda.lambda_function_arn
      events        = ["s3:ObjectCreated:*"]
    }
  }
}

module "ingestion_transfer" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "4.1.0"

  bucket = module.processed_bucket.s3_bucket_id

  lambda_notifications = {
    ingestion_notify = {
      function_name = module.transfer_lambda.lambda_function_name
      function_arn  = module.transfer_lambda.lambda_function_arn
      events        = ["s3:ObjectCreated:*"]
    }
  }
}

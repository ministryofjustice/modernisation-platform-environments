module "ingestion_landing_bucket_notification" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "5.1.0"

  bucket = module.landing_bucket.s3_bucket_id

  eventbridge = true

  lambda_notifications = {
    ingestion_scan = {
      function_name = module.scan_lambda.lambda_function_name
      function_arn  = module.scan_lambda.lambda_function_arn
      events        = ["s3:ObjectCreated:*"]
    }
  }
}

module "ingestion_transfer_bucket_notification" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "5.1.0"

  bucket = module.processed_bucket.s3_bucket_id

  lambda_notifications = {
    ingestion_notify = {
      function_name = module.transfer_lambda.lambda_function_name
      function_arn  = module.transfer_lambda.lambda_function_arn
      events        = ["s3:ObjectCreated:*"]
    }
  }
}

module "ingestion_quarantine_bucket_notification" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "5.1.0"

  bucket = module.quarantine_bucket.s3_bucket_id

  create_sns_policy = false

  sns_notifications = {
    quarantine_sns = {
      topic_arn = module.quarantined_topic.topic_arn
      events    = ["s3:ObjectCreated:*"]
    }
  }
}

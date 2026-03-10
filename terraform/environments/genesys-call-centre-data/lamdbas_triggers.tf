module "virus_scan_file_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-received-files-bucket.bucket
  lambda_function_name = module.virus_scan_file.lambda_function_name
  bucket_prefix        = local.bucket_prefix
  maximum_concurrency  = 1000
}


resource "aws_s3_bucket_notification" "virus_scan_file" {
  bucket = module.s3-received-files-bucket.bucket.id

  queue {
    queue_arn = module.virus_scan_file_sqs.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.virus_scan_file_sqs]
}

resource "aws_athena_workgroup" "test" {
  name = "test"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3_bucket.s3_bucket_id}/athena-query-results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = module.kms_key.key_arn
      }
    }
  }
}

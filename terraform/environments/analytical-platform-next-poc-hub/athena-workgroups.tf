resource "aws_athena_workgroup" "main" {
  name = "main"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.mojap_next_poc_athena_query_s3_bucket.s3_bucket_id}/athena-query-results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = module.s3_mojap_next_poc_athena_query_kms_key.key_arn
      }
    }
  }
}

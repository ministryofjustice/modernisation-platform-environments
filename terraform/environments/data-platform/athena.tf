
resource "aws_athena_workgroup" "data_product_athena_workgroup" {
  name = "data_product_workgroup"

  configuration {
    enforce_workgroup_configuration    = false
    publish_cloudwatch_metrics_enabled = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
    result_configuration {
      output_location = "s3://athena-data-product-query-results-${data.aws_caller_identity.current.account_id}"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
    }
  }
}

resource "aws_cloudwatch_event_target" "athena_load_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.object_created_raw_data.name
  target_id = "athena"
  arn       = aws_lambda_function.athena_load.arn
}

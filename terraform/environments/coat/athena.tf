resource "aws_athena_workgroup" "coat_cur_report" {
  name = "coat_cur_report"

  configuration {
    result_configuration {
      output_location = "s3://coat-${local.environment}-cur-v2-hourly/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true
  }

  tags = local.tags
}
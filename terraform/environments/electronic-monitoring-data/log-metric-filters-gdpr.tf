resource "aws_cloudwatch_log_metric_filter" "batch_jq_error_filter" {
  name           = "GDPR-Batch-JQ-Error-Filter"
  pattern        = "\"parse error\"" # The exact text you are looking for in the logs
  log_group_name = "/aws/batch/job"  # The default AWS Batch log group

  metric_transformation {
    name      = "ManifestParseErrors"
    namespace = "GDPR_Batch_Custom_Metrics"
    value     = "1" # Increment the graph by 1 every time this text is printed
  }
}
resource "aws_cloudwatch_dashboard" "gdpr_batch_dashboard" {
  count          = local.is-production || local.is-development || local.is-preproduction ? 1 : 0
  dashboard_name = "EMDS-GDPR-Batch-Operations-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Batch", "JobsSucceed", "JobQueue", aws_batch_job_queue.shred_unstructured_from_zip_batch_queue[0].name],
            [".", "JobsFailed", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "Job Success vs Failure (Over Time)"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Batch", "JobsRunnable", "JobQueue", aws_batch_job_queue.shred_unstructured_from_zip_batch_queue[0].name],
            [".", "JobsRunning", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "Queue Depth vs Running Jobs"
          period  = 300
        }
      }
    ]
  })
}
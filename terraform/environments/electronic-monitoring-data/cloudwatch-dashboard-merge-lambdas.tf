locals {
  lambda_functions = {
    merge_staged_position_lambda_ops = "merge_mdss_staged_position"
    merge_staged_event_lambda_ops    = "merge_mdss_staged_event"
    merge_ac_position_lambda_ops     = "merge_ac_position"
    merge_emdi_position_lambda_ops   = "merge_emdi_position"
  }
}

locals {
  merge_lambda_widgets = {
    for dashboard, lambda_name in local.lambda_functions :
    dashboard => [
      {
        # --------------------------
        # Queries passed
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Total Successful Queries"
          region = "eu-west-2"
          stat   = "Sum"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "SuccessfulQueries",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Queries failed
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Total Failed Queries"
          region = "eu-west-2"
          stat   = "Sum"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "FailedQueries",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Polls made
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Athena Polls"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "PollsMade",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Data scanned
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Total Data Scanned"
          region = "eu-west-2"
          stat   = "Sum"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "DataScanned",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Execution time
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Execution Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "ExecutionTime",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Queue time
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Query Queue Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "TimeInQueue",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Planning time
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Query Plan Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "QueryPlanTime",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
      {
        # --------------------------
        # Lambda processing time
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Lambda Processing Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "AWS/Lambda",
              "LambdaProcessingTime",
              "FunctionName",
              lambda_name
            ]
          ]
        }
      },
    ]
  }
}

resource "aws_cloudwatch_dashboard" "merge_staged_position_lambda_ops" {
  dashboard_name = "merge-staged-position-lambda-ops"
  dashboard_body = jsonencode({
    widgets = local.merge_lambda_widgets["merge_staged_position_lambda_ops"]
  })
}

resource "aws_cloudwatch_dashboard" "merge_staged_event_lambda_ops" {
  dashboard_name = "merge-staged-event-lambda-ops"
  dashboard_body = jsonencode({
    widgets = local.merge_lambda_widgets["merge_staged_event_lambda_ops"]
  })
}

resource "aws_cloudwatch_dashboard" "merge_ac_position_lambda_ops" {
  dashboard_name = "merge-ac-position-lambda-ops"
  dashboard_body = jsonencode({
    widgets = local.merge_lambda_widgets["merge_ac_position_lambda_ops"]
  })
}

resource "aws_cloudwatch_dashboard" "merge_emdi_position_lambda_ops" {
  dashboard_name = "merge-emdi-position-lambda-ops"
  dashboard_body = jsonencode({
    widgets = local.merge_lambda_widgets["merge_emdi_position_lambda_ops"]
  })
}
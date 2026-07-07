locals {
    merge_lambda_widgets = [
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
          title  = "Successful Queries"
          region = "eu-west-2"
          stat   = "Sum"
          period = 180
          metrics = [
            ["AWS/Lambda",
            "TotalSuccessfulQueries"]
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
          title  = "Failed Queries"
          region = "eu-west-2"
          stat   = "Sum"
          period = 180
          metrics = [
            ["AWS/Lambda",
            "TotalFailedQueries"]
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
          title  = "Average Athena polls"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["AWS/Lambda",
            "AveragePollsMade"]
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
            ["AWS/Lambda",
            "AverageDataScanned"]
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
            ["AWS/Lambda",
            "AverageExecutionTime"]
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
            ["AWS/Lambda",
            "AverageTimeInQueue"]
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
            ["AWS/Lambda",
            "AverageQueryPlanTime"]
          ]
        }
      },


    ]
}

resource "aws_cloudwatch_dashboard" "merge_staged_position_lambda_ops" {
    dashboard_name = "merge-staged-position-lambda-ops-${local.environment_shorthand}"  
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_staged_event_lambda_ops" {
    dashboard_name = "merge-staged-event-lambda-ops-${local.environment_shorthand}" 
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_ac_position_lambda_ops" {
    dashboard_name = "merge-ac-position-lambda-ops-${local.environment_shorthand}" 
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_emdi_position_lambda_ops" {
    dashboard_name = "merge-emdi-position-lambda-ops-${local.environment_shorthand}"  
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

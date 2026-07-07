locals {
    merge_lambda_widgets = [
      {
      # --------------------------
      # Queries passed
      # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Successful Queries"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
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
        width  = 12
        height = 6
        properties = {
          title  = "Failed Queries"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
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
        width  = 12
        height = 6
        properties = {
          title  = "Athena polls"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
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
        width  = 12
        height = 6
        properties = {
          title  = "Data Scanned"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
          ]
        }
      },
      {
      # --------------------------
      # Total execution time
      # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Total Execution Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
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
        width  = 12
        height = 6
        properties = {
          title  = "Queue Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
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
        width  = 12
        height = 6
        properties = {
          title  = "Queue Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            ["TestPlaceholder",
            "TestPlaceholder"]
          ]
        }
      },


    ]
}

resource "aws_cloudwatch_dashboard" "merge_staged_position_lambda_ops" {
    dashboard_name = "merge-staged-position-lambda-ops${local.environment_shorthand}"  
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_staged_event_lambda_ops" {
    dashboard_name = "merge-staged-event-lambda-ops${local.environment_shorthand}" 
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_ac_position_lambda_ops" {
    dashboard_name = "merge-ac-position-lambda-ops${local.environment_shorthand}" 
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_emdi_position_lambda_ops" {
    dashboard_name = "merge-emdi-position-lambda-ops${local.environment_shorthand}"  
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }

resource "aws_cloudwatch_dashboard" "merge_staged_position_lambda_ops" {
  dashboard_name = "merge-staged-position-lambda-ops${local.environment_shorthand}"
    dashboard_body = jsonencode({
        widgets = local.merge_lambda_widgets
        })
    }
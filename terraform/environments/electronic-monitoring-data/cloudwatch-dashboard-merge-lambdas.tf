locals {
  lambda_functions = {
    merge_staged_position_lambda_ops = module.merge_mdss_staged_position[0].lambda_function_name
    merge_staged_event_lambda_ops    = module.merge_mdss_staged_event[0].lambda_function_name
    merge_ac_position_lambda_ops     = module.merge_ac_position[0].lambda_function_name
    merge_emdi_position_lambda_ops   = module.merge_emdi_position[0].lambda_function_name
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
          period = 60
          metrics = [
            [
              "EM/MergeLambdas",
              "SuccessfulQueries",
              "FunctionName",
              lambda_name,
              {
                color = "#228B22"
              }
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
          period = 60
          metrics = [
            [
              "EM/MergeLambdas",
              "FailedQueries",
              "FunctionName",
              lambda_name,
              {
                color = "#E34234"
              }
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
              "EM/MergeLambdas",
              "DataScanned",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
            ]
          ]
        }
      },
      {
        # --------------------------
        # Execution time (total)
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Total Execution Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "EM/MergeLambdas",
              "TotalExecutionTime",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
            ]
          ]
          annotations = {
            horizontal = [
              {
                value = 180000
                label = "Warning - High",
                color = "#E34234"
              }
            ]
          }
        }
      },
      {
        # --------------------------
        # Execution time (engine)
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Engine Execution Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "EM/MergeLambdas",
              "EngineExecutionTime",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
            ]
          ]
          annotations = {
            horizontal = [
              {
                value = 180000
                label = "Warning - High",
                color = "#E34234"
              }
            ]
          }
        }
      },
      {
        # --------------------------
        # Processing time (service)
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Service Processing Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "EM/MergeLambdas",
              "ServiceProcessingTime",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
            ]
          ]
          annotations = {
            horizontal = [
              {
                value = 180000
                label = "Warning - High",
                color = "#E34234"
              }
            ]
          }
        }
      },
      {
        # --------------------------
        # Pre-processing time (service)
        # --------------------------
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Average Service Pre-Processing Time"
          region = "eu-west-2"
          stat   = "Average"
          period = 180
          metrics = [
            [
              "EM/MergeLambdas",
              "ServicePreProcessingTime",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
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
              "EM/MergeLambdas",
              "QueryQueueTime",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
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
              "EM/MergeLambdas",
              "QueryPlanningTime",
              "FunctionName",
              lambda_name,
              {
                color = "#00008B"
              }
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
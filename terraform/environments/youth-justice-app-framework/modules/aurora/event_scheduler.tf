resource "aws_iam_role" "rds_scheduler" {
  count               = var.create_sheduler ? 1 : 0
  name                = "rds-scheduler-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_scheduler" {
  count     = var.create_sheduler ? 1 : 0
  role      = aws_iam_role.rds_scheduler[0].id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:StartDBCluster",
          "rds:StopDBCluster",
          "rds:DescribeDBClusters"
        ]
        Resource = "arn:aws:rds:eu-west-2:${var.aws_account_id}:db:*"
      }
    ]
  })
}


resource "aws_scheduler_schedule" "rds_start" {
  count                        = var.create_sheduler ? 1 : 0
  name                         = "rds-start-weekdays"
  schedule_expression_timezone = "Europe/London"
  schedule_expression          = "cron(0 7 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBCluster"
    role_arn = aws_iam_role.rds_scheduler[0].arn

    input = jsonencode({
      DbClusterIdentifier = var.name
    })
  }
}


resource "aws_scheduler_schedule" "rds_stop" {
  count                        = var.create_sheduler ? 1 : 0
  name                         = "rds-stop-weekdays"
  schedule_expression_timezone = "Europe/London"
  schedule_expression          = "cron(0 20 ? * MON-FRI *)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBCluster"
    role_arn = aws_iam_role.rds_scheduler[0].arn

    input = jsonencode({
      DbClusterIdentifier = var.name
    })
  }
}

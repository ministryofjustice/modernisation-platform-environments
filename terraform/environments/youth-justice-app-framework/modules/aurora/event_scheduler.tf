resource "aws_iam_role" "rds_scheduler" {
  name = "rds-scheduler-role"

  assume_role_policy = jsonencode({
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
  role = aws_iam_role.rds_scheduler.id

  policy = jsonencode({
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
  name                         = "rds-start-weekdays"
  schedule_expression_timezone = "Europe/London"
  schedule_expression          = "cron(0 7 ? * MON-FRI *)" # 07:00 UTC Mon–Fri

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBCluster"
    role_arn = aws_iam_role.rds_scheduler.arn

    input = jsonencode({
      DbClusterIdentifier = var.name
    })
  }
}


resource "aws_scheduler_schedule" "rds_stop" {
  name                         = "rds-stop-weekdays"
  schedule_expression_timezone = "Europe/London"
  schedule_expression          = "cron(0 20 ? * MON-FRI *)" # 20:00 UTC Mon–Fri

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBCluster"
    role_arn = aws_iam_role.rds_scheduler.arn

    input = jsonencode({
      DbClusterIdentifier = var.name
    })
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_over_threshold" {
  count              = var.create_rds ? 1 : 0
  alarm_name         = "${var.name}-rds-cpu-threshold"
  alarm_description  = "Triggers alarm if RDS CPU crosses a threshold"
  namespace          = "AWS/RDS"
  metric_name        = "CPUUtilization"
  statistic          = "Average"
  period             = "60"
  evaluation_periods = "5"
  # add sns topic later
  #  alarm_actions       = [aws_sns_topic.alerting.arn]
  #  ok_actions          = [aws_sns_topic.alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_memory_over_threshold" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.name}-rds-memory-threshold"
  alarm_description   = "Triggers alarm if RDS Memory crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "10"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "800000000"
  treat_missing_data  = "missing"
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency_over_threshold" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.name}-rds-read-latency-threshold"
  alarm_description   = "Triggers alarm if RDS read latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency_over_threshold" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.name}-rds-write-latency-threshold"
  alarm_description   = "Triggers alarm if RDS write latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "WriteLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_over_threshold" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.name}-rds-db-connections-threshold"
  alarm_description   = "Triggers alarm if RDS database connections crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "100"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_allocated_storage_queue_depth_over_threshold" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.name}-rds-queue-depth-threshold"
  alarm_description   = "Triggers alarm if RDS database queue depth crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DiskQueueDepth"
  statistic           = "Average"
  period              = "300"
  evaluation_periods  = "5"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "60"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_less_than_threshold" {
  count               = var.create_rds ? 1 : 0
  alarm_name          = "${var.name}-rds-freeable-memory-threshold"
  alarm_description   = "Triggers alarm if RDS freeable memory crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "15"
  datapoints_to_alarm = 15
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  threshold           = "800000000"
  treat_missing_data  = "missing"
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this[0].identifier
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

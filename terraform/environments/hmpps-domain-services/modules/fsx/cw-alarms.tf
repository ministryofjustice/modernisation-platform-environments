resource "aws_cloudwatch_metric_alarm" "fsx_filesystem_warning" {
  alarm_name                = "${var.fsx.common_name}-FSXFileSystem-FreeStorageCapacity-cwa--warning"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeStorageCapacity"
  namespace                 = "AWS/FSx"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "6442450944" // 6GB
  alarm_actions             = [var.fsx.sns_alarm_notification_arn]
  ok_actions                = [var.fsx.sns_alarm_notification_arn]
  alarm_description         = "FSx Filesystem Free Storage Capacity is less than 20% (6GB)"
  insufficient_data_actions = []
  tags                      = var.common.tags

  dimensions = {
    FileSystemId = aws_fsx_windows_file_system.fsx.id
  }
}

resource "aws_cloudwatch_metric_alarm" "fsx_filesystem_critical" {
  alarm_name                = "${var.fsx.common_name}-FSXFileSystem-FreeStorageCapacity-cwa--critical"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "FreeStorageCapacity"
  namespace                 = "AWS/FSx"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "3221225472" // 3GB
  alarm_actions             = [var.fsx.sns_alarm_notification_arn]
  ok_actions                = [var.fsx.sns_alarm_notification_arn]
  alarm_description         = "FSx Filesystem Free Storage Capacity is less than 10% (3GB)"
  insufficient_data_actions = []
  tags                      = var.common.tags

  dimensions = {
    FileSystemId = aws_fsx_windows_file_system.fsx.id
  }
}
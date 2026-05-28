
# resource "aws_security_group" "efs_sg" {

#   name        = "${local.application_name}-${local.environment}-repo_home-efs-security-group"
#   description = "Portal repo_home Product EFS Security Group"
#   vpc_id      = data.aws_vpc.shared.id
# }

# resource "aws_vpc_security_group_egress_rule" "efs_repo_home_outbound" {

#   security_group_id = aws_security_group.efs_sg.id
#   cidr_ipv4   = "0.0.0.0/0"
#   ip_protocol = "-1"
# }

# resource "aws_vpc_security_group_ingress_rule" "efs_repo_home_inbound" {

#   security_group_id = aws_security_group.efs_sg.id
#   referenced_security_group_id = aws_security_group.efs_sg.id
#   description = "EFS Rule inbound for repo_home"
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

# #########################################################
# Temp import block for restoring from AWS Backup
# #########################################################

# import {
#   to = aws_efs_file_system.efs
#   id = "fs-0a10c3b13ecda7773"
# }

###########################################################

resource "aws_efs_file_system" "efs" {

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = "true"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-repo_home" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )

}

resource "aws_efs_mount_target" "target_a" {

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [for k, v in local.efs : aws_security_group.efs_product[k].id]
}

resource "aws_efs_mount_target" "target_b" {

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_b.id
  security_groups = [for k, v in local.efs : aws_security_group.efs_product[k].id]
}

resource "aws_efs_mount_target" "target_c" {

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_c.id
  security_groups = [for k, v in local.efs : aws_security_group.efs_product[k].id]
}

resource "aws_cloudwatch_metric_alarm" "efs_connection_repo_home" {
  alarm_name          = "${local.application_name}-${local.environment}-repo-home-efs-connection"
  alarm_description   = "If the instance has lost connection with its EFS system, please investigate."
  comparison_operator = "LessThanThreshold"
  dimensions = {
    FileSystemId = aws_efs_file_system.efs.id
  }
  evaluation_periods = "5"
  metric_name        = "ClientConnections"
  namespace          = "AWS/EFS"
  period             = "60"
  statistic          = "Sum"
  threshold          = 4
  alarm_actions      = [aws_sns_topic.alerting_topic.arn]
  ok_actions         = [aws_sns_topic.alerting_topic.arn]
  treat_missing_data = "breaching"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-repo-home-efs-connection"
    }
  )
}

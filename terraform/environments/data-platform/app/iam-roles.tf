data "aws_iam_policy_document" "rds_enhanced_monitoring_assume" {
  count = local.environment_configuration.rds_monitoring_interval == 0 ? 0 : 1

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = local.environment_configuration.rds_monitoring_interval == 0 ? 0 : 1

  name_prefix        = "${local.component_name}-rds-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring_assume[0].json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = local.environment_configuration.rds_monitoring_interval == 0 ? 0 : 1

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

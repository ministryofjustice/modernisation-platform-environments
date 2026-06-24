module "monitoring" {
  source = "./modules/monitoring"
  # count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0
}

# Import blocks for moving resources from monitoring workspace to data-platform workspace
import {
  to = module.monitoring.module.iam_role.aws_iam_role.this[0]
  id = "data-platform-monitoring"
}

import {
  to = module.monitoring.aws_iam_role_policy_attachment.cloudwatch_read_only_access
  id = "data-platform-monitoring/arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

import {
  to = module.monitoring.aws_iam_role_policy_attachment.amazon_prometheus_query_access
  id = "data-platform-monitoring/arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

import {
  to = module.monitoring.aws_iam_role_policy_attachment.aws_xray_read_only_access
  id = "data-platform-monitoring/arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
}

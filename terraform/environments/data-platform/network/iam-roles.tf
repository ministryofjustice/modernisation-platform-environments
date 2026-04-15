module "vpc_flow_logs_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name            = "${local.application_name}-${local.environment}-vpc-flow-logs"
  use_name_prefix = false

  trust_policy_permissions = {
    VPCFlowLogs = {
      effect = "Allow"
      actions = [
        "sts:AssumeRole"
      ]
      principals = [{
        type        = "Service"
        identifiers = ["vpc-flow-logs.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    S3ReadAccess = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      resources = [
        module.vpc_flow_logs_log_group.cloudwatch_log_group_arn,
        "${module.vpc_flow_logs_log_group.cloudwatch_log_group_arn}:*"
      ]
    }
  }
}

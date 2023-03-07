resource "aws_ssm_document" "cloud_watch_agent" {
  name            = "InstallAndManageCloudWatchAgent"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./templates/install-and-manage-cwagent.yaml")

  tags = merge(
    local.tags,
    {
      Name = "install-and-manage-cloud-watch-agent"
    },
  )
}
resource "aws_cloudwatch_log_group" "groups" {
  for_each          = local.application_data.cw_log_groups
  name              = each.key
  retention_in_days = each.value.retention_days

  tags = merge(
    local.tags,
    {
      Name = each.key
    },
  )
}
resource "aws_ssm_parameter" "cw_agent_config" {
  description = "cloud watch agent config"
  name        = "cloud-watch-config"
  type        = "String"
  value       = file("./templates/cw_agent_config.json")

  tags = merge(local.tags,
    { Name = "cw-config" }
  )
}

resource "aws_ssm_association" "update_ssm_agent" {
  name             = "AWS-UpdateSSMAgent"
  association_name = "update-ssm-agent"
  parameters = {
    allowDowngrade = "false"
  }
  targets {
    # we could just target all instances, but this would also include the bastion, which gets rebuilt everyday
    key    = "tag:name"
    values = [lower(format("ec2-%s-%s-*", local.application_name, local.environment))]
  }
  apply_only_at_cron_interval = false
  schedule_expression         = "cron(30 7 ? * MON *)"
}

data "aws_iam_policy_document" "cloudwatch_datasource" {
  statement {
    sid    = "AllowReadWriteForCloudWatch"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingLogsFromCloudWatch"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetQueryResults",
      "logs:GetLogEvents"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingTagsInstancesRegionsFromEC2"
    effect = "Allow"
    actions = [
      "ec2:DescribeRegions",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingResourcesForTags"
    effect = "Allow"
    actions = [
      "tag:GetResources"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "cloudwatch_datasource_policy" {
  name        = "cloudwatch-datasource-policy"
  path        = "/"
  description = "Policy for the Monitoring Cloudwatch Datasource"
  policy      = data.aws_iam_policy_document.cloudwatch_datasource.json
  tags = merge(
    local.tags,
    {
      Name = "cloudwatch-datasource-policy"
    },
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch_datasource_policy_attach" {
  policy_arn = aws_iam_policy.cloudwatch_datasource_policy.arn
  #role       = aws_iam_role.cloudwatch-datasource-role.name
  role = aws_iam_role.role_stsassume_oracle_base.name

}

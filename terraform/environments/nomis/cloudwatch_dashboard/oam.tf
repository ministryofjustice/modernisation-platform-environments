resource "aws_oam_link" "source_account_oam_link" {
  count           = var.options.enable_hmpps-oem_monitoring ? 1 : 0
  label_template  = "nomis"
  resource_types  = ["AWS::CloudWatch::Metric"]
  sink_identifier = var.monitoring_account_sink_identifier
}

locals {
  policy_names = [
    "CloudWatchReadOnlyAccess",
    "CloudWatchAutomaticDashboardsAccess",
    "AWSXrayReadOnlyAccess"
  ]

  policy = {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : var.monitoring_account_id
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  }
}

data "aws_iam_policy" "policy" {
  for_each = toset(local.policy_names)
  name     = each.value
}

resource "aws_iam_role" "aws_cloudwatch_metrics_role" {
  count              = var.options.enable_hmpps-oem_monitoring ? 1 : 0
  name               = "CloudWatch-CrossAccountSharingRole"
  assume_role_policy = jsonencode(local.policy)
}

resource "aws_iam_role_policy_attachment" "policy" {
  for_each = toset([
    for p in local.policy_names : p
    if var.options.enable_hmpps-oem_monitoring
  ])
  policy_arn = data.aws_iam_policy.policy[each.key].arn
  role       = aws_iam_role.aws_cloudwatch_metrics_role[0].name
}

##############################################
### AWS Managed Microsoft AD
##############################################

resource "aws_directory_service_directory" "workspaces_ad" {
  count = local.environment == "development" ? 1 : 0

  name       = local.application_data.accounts[local.environment].ad_directory_name
  short_name = local.application_data.accounts[local.environment].ad_short_name
  password   = random_password.ad_admin_password[0].result
  edition    = local.application_data.accounts[local.environment].ad_edition
  type       = "MicrosoftAD"

  vpc_settings {
    vpc_id     = data.terraform_remote_state.workspace_components.outputs.vpc_id
    subnet_ids = data.terraform_remote_state.workspace_components.outputs.private_subnet_ids
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad" }
  )

  lifecycle {
    ignore_changes = [password]
  }
}

##############################################
### AD Logging
##############################################

#checkov:skip=CKV_AWS_158: CloudWatch Log Group encryption not required for AD logs
#checkov:skip=CKV_AWS_338: Log retention set to 30 days
resource "aws_cloudwatch_log_group" "ad_logs" {
  count = local.environment == "development" ? 1 : 0

  name              = "/aws/directoryservice/${aws_directory_service_directory.workspaces_ad[0].id}"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad-logs" }
  )
}

data "aws_iam_policy_document" "ad_log_policy" {
  count = local.environment == "development" ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    principals {
      identifiers = ["ds.amazonaws.com"]
      type        = "Service"
    }

    resources = ["${aws_cloudwatch_log_group.ad_logs[0].arn}:*"]
    effect    = "Allow"
  }
}

resource "aws_cloudwatch_log_resource_policy" "ad_log_policy" {
  count = local.environment == "development" ? 1 : 0

  policy_document = data.aws_iam_policy_document.ad_log_policy[0].json
  policy_name     = "ad-log-policy-${local.application_name}-${local.environment}"
}

resource "aws_directory_service_log_subscription" "ad_logs" {
  count = local.environment == "development" ? 1 : 0

  directory_id   = aws_directory_service_directory.workspaces_ad[0].id
  log_group_name = aws_cloudwatch_log_group.ad_logs[0].name
}
##############################################
### AWS Managed Microsoft AD
##############################################

resource "aws_directory_service_directory" "workspaces_ad" {

  name       = local.application_data.accounts[local.environment].ad_directory_name
  short_name = local.application_data.accounts[local.environment].ad_short_name
  password   = random_password.ad_admin_password.result
  edition    = local.application_data.accounts[local.environment].ad_edition
  type       = "MicrosoftAD"

  # Enable Directory Service Data API for programmatic user management
  enable_directory_data_access = true

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

  name              = "/aws/directoryservice/${aws_directory_service_directory.workspaces_ad.id}"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ad-logs" }
  )
}

data "aws_iam_policy_document" "ad_log_policy" {

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    principals {
      identifiers = ["ds.amazonaws.com"]
      type        = "Service"
    }

    resources = ["${aws_cloudwatch_log_group.ad_logs.arn}:*"]
    effect    = "Allow"
  }
}

resource "aws_cloudwatch_log_resource_policy" "ad_log_policy" {

  policy_document = data.aws_iam_policy_document.ad_log_policy.json
  policy_name     = "ad-log-policy-${local.application_name}-${local.environment}"
}

resource "aws_directory_service_log_subscription" "ad_logs" {

  directory_id   = aws_directory_service_directory.workspaces_ad.id
  log_group_name = aws_cloudwatch_log_group.ad_logs.name
}
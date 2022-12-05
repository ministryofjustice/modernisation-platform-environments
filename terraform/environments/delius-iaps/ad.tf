# Create Managed AD
resource "aws_directory_service_directory" "active_directory" {
  count = 0 # Do not try to create the AD resource, as we currently do not have required permissions

  name        = "${local.application_name}-${local.environment}.local"
  short_name  = "${replace(local.application_name, "delius-", "")}-${local.environment}" # Form "iaps-development" from "delius-iaps-development" because we need <= 15 chars for NETBIOS name 
  description = "Microsoft AD for ${local.environment}.local"

  type    = "MicrosoftAD"
  edition = "Standard"

  password   = aws_secretsmanager_secret_version.ad_password.secret_string
  enable_sso = false

  vpc_settings {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = slice(data.aws_subnets.private-public.ids, 0, 2) # Retrieve the first 2 subnet ids - must be 2 because 2 DCs are created
  }

  tags = merge(
    local.tags,
    {},
  )

  # Required as AWS does not allow you to change the Admin password post AD Create - you must destroy/recreate 
  # When we run tf plan against an already created AD it will always show the AD needs destroy/create so we ignore
  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

# Set up logging for the Managed AD
# Commented out while we wait for ability to deploy an AD instance
# resource "aws_cloudwatch_log_group" "active_directory" {
#   name              = "/aws/directoryservice/${aws_directory_service_directory.active_directory.id}"
#   retention_in_days = 14
# }

# data "aws_iam_policy_document" "ad-log-policy" {
#   statement {
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#     ]

#     principals {
#       identifiers = ["ds.amazonaws.com"]
#       type        = "Service"
#     }

#     resources = ["${aws_cloudwatch_log_group.active_directory.arn}:*"]

#     effect = "Allow"
#   }
# }

# resource "aws_cloudwatch_log_resource_policy" "active_directory-log-policy" {
#   policy_document = data.aws_iam_policy_document.ad-log-policy.json
#   policy_name     = "ad-log-policy-${local.application_name}-${local.environment}"
# }

# resource "aws_directory_service_log_subscription" "active_directory" {
#   directory_id   = aws_directory_service_directory.active_directory.id
#   log_group_name = aws_cloudwatch_log_group.active_directory.name
# }

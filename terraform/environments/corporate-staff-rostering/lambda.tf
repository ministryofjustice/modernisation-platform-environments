# START: lambda_ad_object_clean_up
locals {
  lambda_ad_object_cleanup = {
    function_name = "AD-Object-Clean-Up"
  }
}

module "ad-clean-up-lambda" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v3.1.0"

  application_name = local.lambda_ad_object_cleanup.function_name
  function_name    = local.lambda_ad_object_cleanup.function_name
  description      = "Lambda to remove corresponding computer object from Active Directory upon server termination"

  package_type     = "Zip"
  filename         = "${path.module}/lambda/ad-clean-up/deployment_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/ad-clean-up/deployment_package.zip")
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60

  create_role = false
  lambda_role = aws_iam_role.lambda-ad-role.arn

  vpc_subnet_ids         = tolist(data.aws_subnets.shared-private.ids)
  vpc_security_group_ids = [module.baseline.security_groups["domain"].id]

  allowed_triggers = {
    Ec2StateChange = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.ec2_state_change_terminated.arn
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "ad-object-clean-up-lambda"
    },
  )
}

resource "aws_cloudwatch_event_rule" "ec2_state_change_terminated" {
  name        = "Ec2StateChangedTerminated"
  description = "Rule to trigger Lambda on EC2 state change"

  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EC2 Instance State-change Notification"],
    "detail" : {
      "state" : ["terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_ad_clean_up" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change_terminated.name
  target_id = "LambdaTarget"
  arn       = module.ad-clean-up-lambda.lambda_function_arn
}

# END: lambda_ad_object_clean_up
# START: lambda_cw_logs_xml_to_json
locals {
  lambda_cw_logs_xml_to_json = {
    monitored_log_group = "cwagent-windows-application"
    function_name       = "cw-logs-xml-to-json"
  }
}

module "lambda_cw_logs_xml_to_json" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  # This is an internal module so commit hashes are not needed
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v3.1.0"

  application_name = local.lambda_cw_logs_xml_to_json.function_name
  function_name    = local.lambda_cw_logs_xml_to_json.function_name
  role_name        = local.lambda_cw_logs_xml_to_json.function_name

  package_type     = "Zip"
  filename         = "${path.module}/lambda/cw-xml-to-json/deployment_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/cw-xml-to-json/deployment_package.zip")
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"

  policy_json_attached = true
  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })

  allowed_triggers = {
    AllowExecutionFromCloudWatch = {
      principal  = "logs.amazonaws.com"
      source_arn = "${module.baseline.cloudwatch_log_groups[local.lambda_cw_logs_xml_to_json.monitored_log_group].arn}:*"
    }
  }

  tags = {}
}

resource "aws_cloudwatch_log_subscription_filter" "cw_logs_xml_to_json" {
  name            = "cw-logs-xml-to-json"
  log_group_name  = local.lambda_cw_logs_xml_to_json.monitored_log_group
  filter_pattern  = ""
  destination_arn = module.lambda_cw_logs_xml_to_json.lambda_function_arn
}
# END: lambda_cw_logs_xml_to_json

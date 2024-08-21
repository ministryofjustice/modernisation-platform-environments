# START: lambda_ad_object_clean_up
locals {
  lambda_ad_object_cleanup = {
    function_name = "AD-Object-Clean-Up"
  }
  deploy_lambda = length(try(module.baseline.security_groups["domain"], [])) > 0 ? 1 : 0
}

module "ad-clean-up-lambda" {
  count = local.deploy_lambda
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

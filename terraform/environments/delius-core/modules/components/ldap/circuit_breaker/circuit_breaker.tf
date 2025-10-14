data "aws_lb_target_group" "ldap-target-group" {
  name = "ldap-${var.env_name}-at-389"
}

locals {
  environment = var.env_name

  ecs_cluster_name     = "delius-core-${var.env_name}-cluster"
  ecs_service_name     = "${var.env_name}-ldap"
  nlb_target_group_arn = data.aws_lb_target_group.ldap-target-group.arn
  nlb_target_port      = 389
  ssm_parameter_name   = "/${var.env_name}/ldap/circuit-breaker"
}

##########################
# SSM parameter (default value CLOSED)
##########################
resource "aws_ssm_parameter" "ldap_circuit_breaker" {
  #checkov:skip=CKV_AWS_34 "ignore"
  name  = local.ssm_parameter_name
  type  = "String"
  value = "CLOSED" # CLOSED = traffic flows, OPEN = circuit broken, no traffic
  tags  = var.tags
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.env_name}-ldap-circuit-breaker-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  #checkov:skip=CKV_AWS_290 "ignore"
  #checkov:skip=CKV_AWS_355 "ignore"
  name = "${var.env_name}-ldap-circuit-breaker-lambda-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "ECSRead"
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBV2Targets"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        "Sid" : "SSMRead",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Resource" : "${aws_ssm_parameter.ldap_circuit_breaker.arn}"
      }
    ]
  })
}

resource "aws_lambda_function" "circuit_breaker" {
  #checkov:skip=CKV_AWS_272 "ignore"
  #checkov:skip=CKV_AWS_115 "ignore"
  #checkov:skip=CKV_AWS_173 "ignore"
  #checkov:skip=CKV_AWS_50 "ignore"
  #checkov:skip=CKV_AWS_116 "ignore"
  #checkov:skip=CKV_AWS_117 "ignore"
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.env_name}-ldap-circuit-breaker"
  role             = aws_iam_role.lambda_role.arn
  handler          = "circuit_breaker.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"

  environment {
    variables = {
      ECS_CLUSTER      = local.ecs_cluster_name
      ECS_SERVICE      = local.ecs_service_name
      TARGET_GROUP_ARN = local.nlb_target_group_arn
      TARGET_PORT      = tostring(local.nlb_target_port)
      SSM_PARAM_NAME   = local.ssm_parameter_name
    }
  }
  depends_on = [aws_iam_role_policy.lambda_policy]
}

##########################
# EventBridge rule: trigger on manual update or PutParameter API calls
##########################
resource "aws_cloudwatch_event_rule" "ssm_put_parameter_rule" {
  name        = "${var.env_name}-ldap-ssm-parameter-change-rule"
  description = "Trigger lambda when SSM parameter for LDAP circuit breaker is changed."
  event_pattern = jsonencode({
    "source" : ["aws.ssm"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["ssm.amazonaws.com"],
      "eventName" : ["PutParameter"],
      "requestParameters" : {
        "name" : [local.ssm_parameter_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule = aws_cloudwatch_event_rule.ssm_put_parameter_rule.name
  arn  = aws_lambda_function.circuit_breaker.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge-in-${var.env_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.circuit_breaker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ssm_put_parameter_rule.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/assets/circuit_breaker_lambda.zip"
  source_file = "${path.module}/python/circuit_breaker.py"
}

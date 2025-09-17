locals {
  camel_case_api_name = join("", [for word in split("_", var.api_name) : title(word)])
  synced              = var.sync ? "Sync" : ""
  output              = var.sync ? ".output" : ""
}

# --------------------------------------------------------
# Main API Gateway resources
# --------------------------------------------------------

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = var.api_name
  description = var.api_description

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = var.api_path
}

resource "aws_api_gateway_method" "method" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_resource.resource.id
  http_method          = var.http_method
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.request_validator.id
  request_models = {
    "application/json" = aws_api_gateway_model.model.name
  }
}

# --------------------------------------------------------
# API Validator
# --------------------------------------------------------

resource "aws_api_gateway_request_validator" "request_validator" {
  rest_api_id                 = aws_api_gateway_rest_api.api_gateway.id
  name                        = "${local.camel_case_api_name}RequestValidator"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "model" {
  rest_api_id  = aws_api_gateway_rest_api.api_gateway.id
  name         = "${local.camel_case_api_name}Model"
  content_type = "application/json"
  schema       = jsonencode(var.schema)
}

# --------------------------------------------------------
# IAM Role for API Gateway
# --------------------------------------------------------

data "aws_iam_policy_document" "gateway_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "api_gateway_role" {
  name               = "${var.api_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.gateway_role_policy.json
}

# -------------------------------------------------------
# Policy to execute step function
# -------------------------------------------------------

data "aws_iam_policy_document" "trigger_step_function_policy" {
  statement {
    actions   = ["states:StartExecution", "states:StartSyncExecution"]
    effect    = "Allow"
    resources = [var.step_function.arn]
  }
}

resource "aws_iam_policy" "trigger_step_function_policy" {
  name   = "trigger-${substr(var.step_function.id, 0, 50)}-policy"
  policy = data.aws_iam_policy_document.trigger_step_function_policy.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_trigger_step_function_policy_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.trigger_step_function_policy.arn
}

# -------------------------------------------------------
# API integration with step function
# -------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_integration" "step_function_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/Start${local.synced}Execution"

  credentials = aws_iam_role.api_gateway_role.arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.json('$'))",
  "stateMachineArn": "${var.step_function.arn}"
}
EOF
  }
}

# -------------------------------------------------------
# Deployment and stages
# -------------------------------------------------------

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.step_function_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  #checkov:skip=CKV_AWS_120: "Ensure API Gateway caching is enabled, Skipping for expense reasons, already cached in settings"
  #checkov:skip=CKV2_AWS_29: "Ensure public API gateway are protected by WAF, done below: aws_wafv2_web_acl_association"
  #checkov:skip=CKV2_AWS_77: "Log4j protection implemented via AWSManagedRulesKnownBadInputsRuleSet in associated WAF"
  for_each              = { for stage in var.stages : stage.stage_name => stage }
  deployment_id         = aws_api_gateway_deployment.deployment.id
  rest_api_id           = aws_api_gateway_rest_api.api_gateway.id
  stage_name            = each.value.stage_name
  description           = each.value.stage_description
  client_certificate_id = aws_api_gateway_client_certificate.certificate.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs[each.key].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
  xray_tracing_enabled = true
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  response_templates = {
    "application/json" = <<EOF
#set ($parsedPayload = $util.parseJson($input.json('$.${local.output}')))
$parsedPayload
EOF
  }
  depends_on = [
    aws_api_gateway_integration.step_function_integration
  ]
}

resource "aws_api_gateway_integration_response" "integration_response_500" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "500"

  response_templates = {
    "application/json" = "{\"message\": \"Internal error from Step Function.\"}"
  }
  selection_pattern = ".*\"status\":500.*"
  depends_on = [
    aws_api_gateway_integration.step_function_integration
  ]
}

# -------------------------------------------------------
# Key set up
# -------------------------------------------------------

resource "aws_api_gateway_usage_plan" "usage_plan" {
  for_each    = { for stage in var.stages : stage.stage_name => stage }
  name        = "${each.value.stage_name}UsagePlan"
  description = "Usage plan for ${each.value.stage_name} access"
  throttle_settings {
    burst_limit = each.value.burst_limit
    rate_limit  = each.value.rate_limit
  }
  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage  = aws_api_gateway_stage.stage[each.key].stage_name
  }
}


resource "aws_api_gateway_method_settings" "settings" {
  for_each    = { for stage in var.stages : stage.stage_name => stage }
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.stage[each.key].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = each.value.throttling_burst_limit
    throttling_rate_limit  = each.value.throttling_rate_limit
    caching_enabled        = true
    cache_ttl_in_seconds   = 300
    cache_data_encrypted   = true
  }
  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch_role_policy]
}


# -------------------------------------------------------
# Cloudwatch logs
# -------------------------------------------------------

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for now"
  for_each          = { for stage in var.stages : stage.stage_name => stage }
  name              = "/aws/apigateway/${var.api_name}-${each.key}"
  retention_in_days = 400
}


resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_role_policy" {
  for_each   = { for stage in var.stages : stage.stage_name => stage }
  role       = aws_iam_role.api_gateway_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

data "aws_iam_policy_document" "cloudwatch" {
  for_each = { for stage in var.stages : stage.stage_name => stage }
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = [aws_cloudwatch_log_group.api_gateway_logs[each.key].arn, aws_cloudwatch_log_group.waf_log_group.arn]
  }
}
resource "aws_iam_role_policy" "cloudwatch" {
  for_each = { for stage in var.stages : stage.stage_name => stage }
  name     = "cloudwatch-log-api-${replace(var.api_name, "_", "-")}-stage-${replace(each.key, "_", "-")}"
  role     = aws_iam_role.api_gateway_role.id
  policy   = data.aws_iam_policy_document.cloudwatch[each.key].json
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
}

# -------------------------------------------------------
# certificate and waf
# -------------------------------------------------------

resource "aws_api_gateway_client_certificate" "certificate" {
  description = "Client certificate for API Gateway ${var.api_name}"
}

resource "aws_wafv2_web_acl" "api_gateway" {
  name        = "${var.api_name}-waf"
  description = "WAF for API Gateway ${var.api_name}"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }

  rule {
    name     = "Log4j-Block"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.api_name}-log4j-block"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "Common-Rules"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.api_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.api_name}-waf"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "api_gateway_association" {
  for_each     = { for stage in var.stages : stage.stage_name => stage }
  resource_arn = aws_api_gateway_stage.stage[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.api_gateway.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "api_gateway_waf_logs" {
  resource_arn = aws_wafv2_web_acl.api_gateway.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf_log_group.arn
  ]
}

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "waf_log_group" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for now"
  name              = "aws-waf-logs-${var.api_name}"
  retention_in_days = 400
}

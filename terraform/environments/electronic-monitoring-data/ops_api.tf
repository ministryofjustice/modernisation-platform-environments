# ------------------------------------------------------------------------------
# Central operational API
# ------------------------------------------------------------------------------

locals {
  ops_api_optional_routes_enabled = (
    local.is-development || local.is-preproduction || local.is-production
  )
  ops_api_stage_name = "v1"

  ops_api_ears_sars_principals = local.is-preproduction || local.is-production ? [
    module.emd_ears_sars_cp_role[0].iam_role_arn,
  ] : tolist(data.aws_iam_roles.mod_plat_roles.arns)

  ops_api_step_function_routes = {
    zip_file = {
      path              = "zip-file"
      enabled           = true
      state_machine_arn = module.get_zipped_file_api.arn
      start_action      = "StartSyncExecution"
      response_type     = "express"
      status_enabled    = false
      burst_limit       = 200
      rate_limit        = 2000
      principals        = [module.cmt_front_end_assumable_role.iam_role_arn]
      schema = jsonencode({
        type = "object"
        properties = {
          file_name     = { type = "string" }
          zip_file_name = { type = "string" }
        }
        required = ["file_name", "zip_file_name"]
      })
    }
    ears_sars = {
      path    = "ears-sars"
      enabled = local.ops_api_optional_routes_enabled
      state_machine_arn = (
        local.ops_api_optional_routes_enabled
        ? module.ears_sars_step_function[0].arn
        : ""
      )
      start_action   = "StartExecution"
      response_type  = "standard"
      status_enabled = true
      burst_limit    = 20
      rate_limit     = 200
      principals     = local.ops_api_ears_sars_principals
      schema = jsonencode({
        type = "object"
        properties = {
          legacy_subject_id      = { type = ["string", "integer"] }
          legacy_order_id        = { type = ["string", "integer"] }
          priority               = { type = "string" }
          monitoring_requirement = { type = "string" }
          request_types = {
            type  = "array"
            items = { type = "string" }
          }
          information_requested_from = { type = "string" }
          information_requested_to   = { type = "string" }
        }
        required = [
          "legacy_subject_id",
          "legacy_order_id",
          "priority",
          "monitoring_requirement",
          "request_types",
          "information_requested_from",
          "information_requested_to",
        ]
      })
    }
    cadt = {
      path              = "cadt"
      enabled           = true
      state_machine_arn = module.trigger_cadt_step_function.arn
      start_action      = "StartExecution"
      response_type     = "standard"
      status_enabled    = true
      burst_limit       = 20
      rate_limit        = 200
      principals        = [module.cadt_api_trigger.iam_role_arn]
      schema = jsonencode({
        type = "object"
        properties = {
          full_refresh = { type = "boolean" }
          all_models   = { type = "boolean" }
        }
        required = [
          "full_refresh",
          "all_models",
        ]
      })
    }
  }

  ops_api_routes = {
    for name, route in local.ops_api_step_function_routes :
    name => route if route.enabled
  }

  ops_api_status_routes = {
    for name, route in local.ops_api_routes :
    name => route if route.status_enabled
  }

  ops_api_p1_routes = local.ops_api_optional_routes_enabled ? toset([
    "add",
    "remove",
  ]) : toset([])

  ops_api_standard_response = <<EOF
#set($body = $input.path('$'))
{
  "id": "$body.executionArn",
  "status": "ACCEPTED",
  "message": "Workflow started successfully"
}
EOF

  ops_api_express_response = <<EOF
#set ($parsedPayload = $util.parseJson($input.json('$..output')))
$parsedPayload
EOF

  ops_api_status_response = <<EOF
#set($input = $input.path('$'))
#set($type = $input.get("__type"))
#if($type && $type.contains("ExecutionDoesNotExist"))
    #set($context.responseOverride.status = 404)
    {
      "error": "NotFound",
      "cause": "Step Function execution with the provided ID does not exist."
    }
#else
    {
      "execution_id": "$input.name",
      "status": "$input.status",
      #if($input.status == "SUCCEEDED")
        "output": $input.output
      #elseif($input.status == "FAILED")
        "error": "$util.escapeJavaScript($input.error)",
        "cause": "$util.escapeJavaScript($input.cause)"
      #else
        "output": ""
      #end
    }
#end
EOF
}

resource "aws_api_gateway_rest_api" "ops_api" {
  name        = "ops_api"
  description = "Central operational API for Electronic Monitoring Data."

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [data.aws_vpc_endpoint.api_gateway.id]
    ip_address_type  = "dualstack"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ops_api" {
  dynamic "statement" {
    for_each = local.ops_api_routes
    iterator = route

    content {
      sid    = "Allow${replace(title(route.key), "_", "")}Requests"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = route.value.principals
      }

      actions = ["execute-api:Invoke"]
      resources = concat(
        [
          "${aws_api_gateway_rest_api.ops_api.execution_arn}/*/POST/${route.value.path}",
        ],
        route.value.status_enabled ? [
          "${aws_api_gateway_rest_api.ops_api.execution_arn}/*/GET/${route.value.path}/status/*",
        ] : [],
      )
    }
  }

  dynamic "statement" {
    for_each = local.ops_api_optional_routes_enabled ? [1] : []

    content {
      sid    = "AllowP1ExportRequests"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = local.is-preproduction || local.is-production ? [
          module.emd_update_p1_cp_role[0].iam_role_arn,
        ] : tolist(data.aws_iam_roles.mod_plat_roles.arns)
      }

      actions = ["execute-api:Invoke"]
      resources = [
        for path in local.ops_api_p1_routes :
        "${aws_api_gateway_rest_api.ops_api.execution_arn}/*/POST/${path}"
      ]
    }
  }

  statement {
    sid    = "DenyRequestsOutsideApiGatewayVpcEndpoint"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.ops_api.execution_arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values   = [data.aws_vpc_endpoint.api_gateway.id]
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "ops_api" {
  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  policy      = data.aws_iam_policy_document.ops_api.json
}

# ------------------------------------------------------------------------------
# Requests and routes
# ------------------------------------------------------------------------------

resource "aws_api_gateway_request_validator" "ops_api" {
  rest_api_id                 = aws_api_gateway_rest_api.ops_api.id
  name                        = "OpsApiRequestValidator"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id  = aws_api_gateway_rest_api.ops_api.id
  name         = "OpsApi${replace(title(each.key), "_", "")}Model"
  content_type = "application/json"
  schema       = each.value.schema
}

resource "aws_api_gateway_resource" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  parent_id   = aws_api_gateway_rest_api.ops_api.root_resource_id
  path_part   = each.value.path
}

resource "aws_api_gateway_method" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id          = aws_api_gateway_rest_api.ops_api.id
  resource_id          = aws_api_gateway_resource.ops_api[each.key].id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.ops_api.id
  request_models = {
    "application/json" = aws_api_gateway_model.ops_api[each.key].name
  }
}

resource "aws_api_gateway_resource" "ops_api_status" {
  for_each = local.ops_api_status_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  parent_id   = aws_api_gateway_resource.ops_api[each.key].id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "ops_api_execution" {
  for_each = local.ops_api_status_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  parent_id   = aws_api_gateway_resource.ops_api_status[each.key].id
  path_part   = "{execution_id}"
}

resource "aws_api_gateway_method" "ops_api_status" {
  for_each = local.ops_api_status_routes

  rest_api_id          = aws_api_gateway_rest_api.ops_api.id
  resource_id          = aws_api_gateway_resource.ops_api_execution[each.key].id
  http_method          = "GET"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.ops_api.id
  request_parameters = {
    "method.request.path.execution_id" = true
  }
}

resource "aws_api_gateway_model" "ops_api_p1" {
  count        = local.ops_api_optional_routes_enabled ? 1 : 0
  rest_api_id  = aws_api_gateway_rest_api.ops_api.id
  name         = "OpsApiP1ExportModel"
  content_type = "application/json"
  schema = jsonencode({
    type = "object"
    properties = {
      case_numbers = {
        type  = "array"
        items = { type = "integer" }
      }
      run_historic = { type = "boolean" }
    }
    required = ["case_numbers", "run_historic"]
  })
}

resource "aws_api_gateway_resource" "ops_api_p1" {
  for_each = local.ops_api_p1_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  parent_id   = aws_api_gateway_rest_api.ops_api.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "ops_api_p1" {
  for_each = local.ops_api_p1_routes

  rest_api_id          = aws_api_gateway_rest_api.ops_api.id
  resource_id          = aws_api_gateway_resource.ops_api_p1[each.key].id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.ops_api.id
  request_models = {
    "application/json" = aws_api_gateway_model.ops_api_p1[0].name
  }
}

# ------------------------------------------------------------------------------
# Service integrations
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ops_api" {
  name               = "ops_api-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "ops_api_integrations" {
  statement {
    effect    = "Allow"
    actions   = ["states:StartSyncExecution"]
    resources = [module.get_zipped_file_api.arn]
  }

  statement {
    effect  = "Allow"
    actions = ["states:StartExecution"]
    resources = compact([
      module.trigger_cadt_step_function.arn,
      local.ops_api_optional_routes_enabled ? module.ears_sars_step_function[0].arn : null,
    ])
  }

  statement {
    effect  = "Allow"
    actions = ["states:DescribeExecution"]
    resources = compact([
      "${replace(module.trigger_cadt_step_function.arn, "stateMachine", "execution")}:*",
      local.ops_api_optional_routes_enabled ? "${replace(module.ears_sars_step_function[0].arn, "stateMachine", "execution")}:*" : null,
    ])
  }

  dynamic "statement" {
    for_each = local.ops_api_optional_routes_enabled ? [1] : []

    content {
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = [module.update_p1_export[0].lambda_function_arn]
    }
  }
}

resource "aws_iam_role_policy" "ops_api_integrations" {
  name   = "ops_api_integrations"
  role   = aws_iam_role.ops_api.id
  policy = data.aws_iam_policy_document.ops_api_integrations.json
}

resource "aws_api_gateway_integration" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id             = aws_api_gateway_rest_api.ops_api.id
  resource_id             = aws_api_gateway_resource.ops_api[each.key].id
  http_method             = aws_api_gateway_method.ops_api[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/${each.value.start_action}"
  credentials             = aws_iam_role.ops_api.arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.json('$'))",
  "stateMachineArn": "${each.value.state_machine_arn}"
}
EOF
  }
}

resource "aws_api_gateway_integration" "ops_api_status" {
  for_each = local.ops_api_status_routes

  rest_api_id             = aws_api_gateway_rest_api.ops_api.id
  resource_id             = aws_api_gateway_resource.ops_api_execution[each.key].id
  http_method             = aws_api_gateway_method.ops_api_status[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/DescribeExecution"
  credentials             = aws_iam_role.ops_api.arn

  request_templates = {
    "application/json" = <<EOF
{
  "executionArn": "${replace(each.value.state_machine_arn, "stateMachine", "execution")}:$input.params('execution_id')"
}
EOF
  }
}

resource "aws_api_gateway_integration" "ops_api_p1" {
  for_each = local.ops_api_p1_routes

  rest_api_id             = aws_api_gateway_rest_api.ops_api.id
  resource_id             = aws_api_gateway_resource.ops_api_p1[each.key].id
  http_method             = aws_api_gateway_method.ops_api_p1[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.update_p1_export[0].lambda_function_invoke_arn
  credentials             = aws_iam_role.ops_api.arn
}

# ------------------------------------------------------------------------------
# Responses
# ------------------------------------------------------------------------------

resource "aws_api_gateway_method_response" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api[each.key].id
  http_method = aws_api_gateway_method.ops_api[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api[each.key].id
  http_method = aws_api_gateway_method.ops_api[each.key].http_method
  status_code = aws_api_gateway_method_response.ops_api[each.key].status_code

  response_templates = {
    "application/json" = (
      each.value.response_type == "express"
      ? local.ops_api_express_response
      : local.ops_api_standard_response
    )
  }

  depends_on = [aws_api_gateway_integration.ops_api]
}

resource "aws_api_gateway_method_response" "ops_api_status_200" {
  for_each = local.ops_api_status_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api_execution[each.key].id
  http_method = aws_api_gateway_method.ops_api_status[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "ops_api_status_404" {
  for_each = local.ops_api_status_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api_execution[each.key].id
  http_method = aws_api_gateway_method.ops_api_status[each.key].http_method
  status_code = "404"
}

resource "aws_api_gateway_integration_response" "ops_api_status" {
  for_each = local.ops_api_status_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api_execution[each.key].id
  http_method = aws_api_gateway_method.ops_api_status[each.key].http_method
  status_code = aws_api_gateway_method_response.ops_api_status_200[each.key].status_code

  response_templates = {
    "application/json" = local.ops_api_status_response
  }

  depends_on = [aws_api_gateway_integration.ops_api_status]
}

resource "aws_api_gateway_method_response" "ops_api_p1_200" {
  for_each = local.ops_api_p1_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api_p1[each.key].id
  http_method = aws_api_gateway_method.ops_api_p1[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "ops_api_p1_404" {
  for_each = local.ops_api_p1_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  resource_id = aws_api_gateway_resource.ops_api_p1[each.key].id
  http_method = aws_api_gateway_method.ops_api_p1[each.key].http_method
  status_code = "404"
}

# ------------------------------------------------------------------------------
# Deployment and observability
# ------------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "ops_api" {
  rest_api_id = aws_api_gateway_rest_api.ops_api.id

  triggers = {
    redeployment = sha1(jsonencode({
      resources = concat(
        [for resource in values(aws_api_gateway_resource.ops_api) : resource.id],
        [for resource in values(aws_api_gateway_resource.ops_api_status) : resource.id],
        [for resource in values(aws_api_gateway_resource.ops_api_execution) : resource.id],
        [for resource in values(aws_api_gateway_resource.ops_api_p1) : resource.id],
      )
      methods = concat(
        [for method in values(aws_api_gateway_method.ops_api) : method.id],
        [for method in values(aws_api_gateway_method.ops_api_status) : method.id],
        [for method in values(aws_api_gateway_method.ops_api_p1) : method.id],
      )
      integrations = concat(
        [for integration in values(aws_api_gateway_integration.ops_api) : integration.id],
        [for integration in values(aws_api_gateway_integration.ops_api_status) : integration.id],
        [for integration in values(aws_api_gateway_integration.ops_api_p1) : integration.id],
      )
      method_responses = concat(
        [for response in values(aws_api_gateway_method_response.ops_api) : response.id],
        [for response in values(aws_api_gateway_method_response.ops_api_status_200) : response.id],
        [for response in values(aws_api_gateway_method_response.ops_api_status_404) : response.id],
        [for response in values(aws_api_gateway_method_response.ops_api_p1_200) : response.id],
        [for response in values(aws_api_gateway_method_response.ops_api_p1_404) : response.id],
      )
      integration_responses = concat(
        [for response in values(aws_api_gateway_integration_response.ops_api) : response.id],
        [for response in values(aws_api_gateway_integration_response.ops_api_status) : response.id],
      )
      policy = aws_api_gateway_rest_api_policy.ops_api.policy
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ops_api" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for now"
  name              = "/aws/apigateway/ops_api-${local.ops_api_stage_name}"
  retention_in_days = 400
}

resource "aws_api_gateway_stage" "ops_api" {
  #checkov:skip=CKV_AWS_120: "Operational actions are not cached"
  #checkov:skip=CKV2_AWS_29: "API Gateway is protected by the associated WAF"
  #checkov:skip=CKV2_AWS_77: "Log4j protection is provided by the associated WAF"
  deployment_id = aws_api_gateway_deployment.ops_api.id
  rest_api_id   = aws_api_gateway_rest_api.ops_api.id
  stage_name    = local.ops_api_stage_name
  description   = "Central operational API"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.ops_api.arn
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

  depends_on = [aws_api_gateway_account.global_usage]
}

resource "aws_api_gateway_method_settings" "ops_api" {
  for_each = local.ops_api_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  stage_name  = aws_api_gateway_stage.ops_api.stage_name
  method_path = "${each.value.path}/POST"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = each.value.burst_limit
    throttling_rate_limit  = each.value.rate_limit
  }
}

resource "aws_api_gateway_method_settings" "ops_api_status" {
  for_each = local.ops_api_status_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  stage_name  = aws_api_gateway_stage.ops_api.stage_name
  method_path = "${each.value.path}/status/{execution_id}/GET"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = each.value.burst_limit
    throttling_rate_limit  = each.value.rate_limit
  }
}

resource "aws_api_gateway_method_settings" "ops_api_p1" {
  for_each = local.ops_api_p1_routes

  rest_api_id = aws_api_gateway_rest_api.ops_api.id
  stage_name  = aws_api_gateway_stage.ops_api.stage_name
  method_path = "${each.key}/POST"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

# ------------------------------------------------------------------------------
# WAF
# ------------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "ops_api" {
  name        = "ops_api-waf"
  description = "WAF for the central operational API"
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
      metric_name                = "ops_api-log4j-block"
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
      metric_name                = "ops_api-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ops_api-waf"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "ops_api" {
  resource_arn = aws_api_gateway_stage.ops_api.arn
  web_acl_arn  = aws_wafv2_web_acl.ops_api.arn
}

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ops_api_waf" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for now"
  name              = "aws-waf-logs-ops_api"
  retention_in_days = 400
}

resource "aws_wafv2_web_acl_logging_configuration" "ops_api" {
  resource_arn = aws_wafv2_web_acl.ops_api.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.ops_api_waf.arn,
  ]
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "ops_api_id" {
  description = "ID of the central operational API Gateway."
  value       = aws_api_gateway_rest_api.ops_api.id
}

output "ops_api_base_url" {
  description = "Base URL for the central operational API Gateway."
  value = format(
    "https://%s.execute-api.%s.amazonaws.com/%s",
    aws_api_gateway_rest_api.ops_api.id,
    data.aws_region.current.name,
    aws_api_gateway_stage.ops_api.stage_name,
  )
}

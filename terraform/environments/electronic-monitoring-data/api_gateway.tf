module "get_zipped_file_api_api" {
  source          = "./modules/api_step_function"
  api_name        = "get_zipped_file_api"
  api_description = "API to trigger step function that gets a zipped file out of storage"
  api_path        = "execute"
  step_function   = module.get_zipped_file_api
  sfn_type        = "express"
  stages = [
    {
      stage_name             = "test",
      stage_description      = "API Stage for testing",
      burst_limit            = 200,
      rate_limit             = 2000,
      throttling_burst_limit = 200,
      throttling_rate_limit  = 2000

    }
  ]
  schema = {
    type = "object"
    properties = {
      file_name     = { type = "string" }
      zip_file_name = { type = "string" }
    }
    required = ["file_name", "zip_file_name"]
  }
  api_version = "0.1.1"
}

module "ears_sars_api" {
  count               = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  source              = "./modules/api_step_function"
  api_name            = "ears_sars_api"
  api_description     = "Ears and Sars API"
  api_path            = "execute"
  step_function       = module.ears_sars_step_function[0]
  sfn_type            = "standard"
  enable_status_check = true
  stages = [
    {
      stage_name             = "request",
      stage_description      = "API Stage for testing",
      burst_limit            = 20,
      rate_limit             = 200,
      throttling_burst_limit = 20,
      throttling_rate_limit  = 200

    }
  ]
  schema = {
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
      "information_requested_to"
    ]
  }
  api_version = "0.1.1"
}

resource "aws_api_gateway_account" "global_usage" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "cloudwatch" {
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

    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

# --------------------------------------------------------------------------------
# update_p1_export networking
# --------------------------------------------------------------------------------

locals {
  shared_ca_name = contains(["prod", "preprod", "stage"], local.environment_shorthand) ? "acm-pca-live" : "acm-pca-non-live"
  update_p1_export_domain_name = "p1-export.${trimsuffix(data.aws_route53_zone.inner.name, ".")}"
}

data "aws_ram_resource_share" "shared_private_ca" {
  name                  = local.shared_ca_name
  resource_owner        = "OTHER-ACCOUNTS"
  resource_share_status = "ACTIVE"
}

resource "aws_acm_certificate" "update_p1_export" {
  domain_name               = local.update_p1_export_domain_name
  certificate_authority_arn = data.aws_ram_resource_share.shared_private_ca.resource_arns[0]
  key_algorithm             = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_security_group" "aws_dns_resolver" {
  provider    = aws.core-vpc
  name        = "dns-resolver"
  description = "Security Group for DNS resolver request"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

locals {
  dns_endpoint_rules = {
    "TCP_53" : {
      "from_port" : 53,
      "to_port" : 53,
      "protocol" : "TCP"
    },
    "UDP_53" : {
      "from_port" : 53,
      "to_port" : 53,
      "protocol" : "UDP"
    }
  }
}

resource "aws_security_group_rule" "ingress_dns_endpoint_traffic" {
  provider          = aws.core-vpc
  for_each          = local.dns_endpoint_rules
  description       = format("VPC to DNS Endpoint traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_dns_endpoint_traffic" {
  provider          = aws.core-vpc
  for_each          = local.dns_endpoint_rules
  description       = format("DNS Endpoint to Domain Controller traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.aws_dns_resolver.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_route53_resolver_endpoint" "inbound_api" {
  provider     = aws.core-vpc

  name      = "inbound-resolver"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.aws_dns_resolver.id]
  ip_address {
    subnet_id = data.aws_subnet.private_subnets_a.id
  }
  ip_address {
    subnet_id = data.aws_subnet.private_subnets_b.id
  }
  ip_address {
    subnet_id = data.aws_subnet.private_subnets_c.id
  }
  tags = local.tags
}

data "aws_iam_policy_document" "update_p1_export_vpc" {
  count = local.is-test ? 0 : 1
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [module.emd_update_p1_cp_role[0].iam_role_arn]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.update_p1_export[0].execution_arn}/*"]
  }
  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values = [
        data.aws_vpc_endpoint.api_gateway.id
      ]
    }
    resources = ["${aws_api_gateway_rest_api.update_p1_export[0].execution_arn}/*"]
  }
}

resource "aws_api_gateway_domain_name" "update_p1_export" {
  domain_name = local.update_p1_export_domain_name

  # For PRIVATE custom domains, use certificate_arn, not regional_certificate_arn.
  certificate_arn = aws_acm_certificate.update_p1_export.arn

  security_policy = "SecurityPolicy_TLS13_1_3_2025_09"
  endpoint_access_mode     = "STRICT"
  routing_mode    = "BASE_PATH_MAPPING_ONLY"

  # This is the custom domain resource policy.
  policy = data.aws_iam_policy_document.update_p1_export_vpc[0].json

  endpoint_configuration {
    types           = ["PRIVATE"]
    ip_address_type = "dualstack"
  }

  tags = local.tags
}

resource "aws_api_gateway_base_path_mapping" "update_p1_export" {
  api_id     = aws_api_gateway_rest_api.update_p1_export[0].id
  stage_name = aws_api_gateway_stage.update_p1_export_stage[0].stage_name
  domain_name    = aws_api_gateway_domain_name.update_p1_export.domain_name
  domain_name_id = aws_api_gateway_domain_name.update_p1_export.domain_name_id
}

data "aws_vpc_endpoint" "api_gateway" {
  provider     = aws.core-vpc
  service_name = "com.amazonaws.eu-west-2.execute-api"
  vpc_id       = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.execute-api"
  }
}

resource "aws_api_gateway_domain_name_access_association" "update_p1_export" {
  provider                       = aws.core-vpc
  domain_name_arn                = aws_api_gateway_domain_name.update_p1_export.arn
  access_association_source      = data.aws_vpc_endpoint.api_gateway.id
  access_association_source_type = "VPCE"

  depends_on = [
    aws_api_gateway_base_path_mapping.update_p1_export
  ]
}

resource "aws_route53_record" "private_api" {
  provider     = aws.core-vpc

  zone_id = data.aws_route53_zone.inner.zone_id
  name    = local.update_p1_export_domain_name
  type    = "A"

  alias {
    name                   = data.aws_vpc_endpoint.api_gateway.dns_entry[0].dns_name
    zone_id                = data.aws_vpc_endpoint.api_gateway.dns_entry[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "allow_cp_access" {
  name        = "allow_cp_access"
  description = "allow cp access"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_cp_access" {
  security_group_id = aws_security_group.allow_cp_access.id

  cidr_ipv4   = "172.20.0.0/16"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

# --------------------------------------------------------------------------------
# update_p1_export
# --------------------------------------------------------------------------------
locals {
  endpoint_type = local.is-development ? {"REGIONAL": null} : {"PRIVATE": data.aws_vpc_endpoint.api_gateway.cidr_blocks}
}

resource "aws_api_gateway_rest_api_policy" "update_p1_export_vpc" {
  count = local.is-test ? 0 : 1
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  policy      = data.aws_iam_policy_document.update_p1_export_vpc[0].json
}


resource "aws_api_gateway_rest_api" "update_p1_export" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  name        = "update_p1_export"
  description = "Access to update the P1 Export."

  lifecycle {
    create_before_destroy = true
  }

endpoint_configuration {
  types            = ["PRIVATE"]
  vpc_endpoint_ids = [data.aws_vpc_endpoint.api_gateway.id]
  ip_address_type  = "dualstack"
}
}

resource "aws_api_gateway_resource" "update_p1_export_add" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  parent_id   = aws_api_gateway_rest_api.update_p1_export[0].root_resource_id
  path_part   = "add"
}

resource "aws_api_gateway_resource" "update_p1_export_remove" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  parent_id   = aws_api_gateway_rest_api.update_p1_export[0].root_resource_id
  path_part   = "remove"
}

resource "aws_api_gateway_method" "update_p1_export_add_post" {
  count                = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id          = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id          = aws_api_gateway_resource.update_p1_export_add[0].id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.update_p1_export[0].id
  request_models = {
    "application/json" = aws_api_gateway_model.update_p1_export[0].name
  }
}

resource "aws_api_gateway_method" "update_p1_export_remove_post" {
  count                = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id          = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id          = aws_api_gateway_resource.update_p1_export_remove[0].id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.update_p1_export[0].id
  request_models = {
    "application/json" = aws_api_gateway_model.update_p1_export[0].name
  }
}

# --------------------------------------------------------
# update_p1_export Validator
# --------------------------------------------------------

resource "aws_api_gateway_request_validator" "update_p1_export" {
  count                       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id                 = aws_api_gateway_rest_api.update_p1_export[0].id
  name                        = "≈RequestValidator"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "update_p1_export" {
  count        = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id  = aws_api_gateway_rest_api.update_p1_export[0].id
  name         = "UpdateP1ExportModel"
  content_type = "application/json"
  schema = jsonencode(
    {
      type = "object"
      properties = {
        case_numbers = {
          type  = "array"
          items = { type = "integer" }
        }
        run_historic = { type = "boolean" }
      }
      required = ["case_numbers", "run_historic"]
    }
  )
}

resource "aws_api_gateway_integration" "update_p1_export_add_lambda_post" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_add[0].id
  http_method = aws_api_gateway_method.update_p1_export_add_post[0].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.update_p1_export[0].lambda_function_invoke_arn
}

resource "aws_api_gateway_integration" "update_p1_export_remove_lambda_post" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_remove[0].id
  http_method = aws_api_gateway_method.update_p1_export_remove_post[0].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.update_p1_export[0].lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "update_p1_export" {
  count = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  depends_on = [
    aws_api_gateway_integration.update_p1_export_add_lambda_post[0],
    aws_api_gateway_integration.update_p1_export_remove_lambda_post[0],
  ]

  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
}

resource "aws_api_gateway_stage" "update_p1_export_stage" {
  count         = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  deployment_id = aws_api_gateway_deployment.update_p1_export[0].id
  rest_api_id   = aws_api_gateway_rest_api.update_p1_export[0].id
  stage_name    = "prod"
}

# -------------------------------------------------------
# certificate and waf
# -------------------------------------------------------

resource "aws_api_gateway_client_certificate" "update_p1_export_certificate" {
  description = "Client certificate for API Gateway update_p1_export"
}

resource "aws_wafv2_web_acl" "update_p1_export_api_gateway" {
  count = local.is-development || local.is-preproduction || local.is-production ? 1 : 0

  name        = "update_p1_export-waf"
  description = "WAF for API Gateway update_p1_export"
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
      metric_name                = "update_p1_export-log4j-block"
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
      metric_name                = "update_p1_export-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "update_p1_export-waf"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "update_p1_export_api_gateway_association" {
  count        = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  resource_arn = aws_api_gateway_stage.update_p1_export_stage[0].arn
  web_acl_arn  = aws_wafv2_web_acl.update_p1_export_api_gateway[0].arn
}

resource "aws_wafv2_web_acl_logging_configuration" "update_p1_export_api_gateway_waf_logs" {
  count        = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  resource_arn = aws_wafv2_web_acl.update_p1_export_api_gateway[0].arn

  log_destination_configs = [
    aws_cloudwatch_log_group.update_p1_export_waf_log_group[0].arn
  ]
}

# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "update_p1_export_waf_log_group" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS, Skipping for now"
  count = local.is-development || local.is-preproduction || local.is-production ? 1 : 0

  name              = "aws-waf-logs-update_p1_export"
  retention_in_days = 400
}

resource "aws_api_gateway_method_response" "add_response_200" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_add[0].id
  http_method = aws_api_gateway_method.update_p1_export_add_post[0].http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "add_status_404" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_add[0].id
  http_method = aws_api_gateway_method.update_p1_export_add_post[0].http_method
  status_code = "404"
}

resource "aws_api_gateway_method_response" "remove_response_200" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_remove[0].id
  http_method = aws_api_gateway_method.update_p1_export_remove_post[0].http_method
  status_code = "200"
}


resource "aws_api_gateway_method_response" "remove_status_404" {
  count       = local.is-development || local.is-preproduction || local.is-production ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.update_p1_export[0].id
  resource_id = aws_api_gateway_resource.update_p1_export_remove[0].id
  http_method = aws_api_gateway_method.update_p1_export_remove_post[0].http_method
  status_code = "404"
}

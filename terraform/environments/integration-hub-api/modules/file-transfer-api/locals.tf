locals {
  resource_application_name = "integration-hub"
  component_name            = "api-platform"
  resource_name_prefix      = "${local.resource_application_name}-${local.component_name}"
  account_id                = data.aws_caller_identity.current.account_id
  region                    = data.aws_region.current.region
  bootstrap_code_root       = "${path.module}/bootstrap-lambdas"

  application_configuration = try(jsondecode(file("${path.module}/application_variables.json")).accounts[var.environment], {})

  api_configuration = {
    cors_allowed_origins             = try(local.application_configuration.api_configuration.cors_allowed_origins, [])
    max_presigned_url_expiry_seconds = try(local.application_configuration.api_configuration.max_presigned_url_expiry_seconds, 3600)
    presigned_url_expiry_seconds     = try(local.application_configuration.api_configuration.presigned_url_expiry_seconds, 900)
  }
  api_docs_configuration = {
    basic_auth_username = try(local.application_configuration.api_configuration.docs.basic_auth_username, "api-docs")
  }
  multipart_configuration = {
    single_put_limit_bytes            = try(local.application_configuration.api_configuration.multipart_upload.single_put_limit_bytes, 5368709120)
    multipart_default_part_size_bytes = try(local.application_configuration.api_configuration.multipart_upload.multipart_default_part_size_bytes, 67108864)
    multipart_max_parts               = try(local.application_configuration.api_configuration.multipart_upload.multipart_max_parts, 10000)
    multipart_initial_presign_parts   = try(local.application_configuration.api_configuration.multipart_upload.multipart_initial_presign_parts, 10)
  }

  auth_roles = {
    for role_name, role in try(local.application_configuration.auth_configuration.roles, {}) : role_name => {
      allowed_client_ids = try(role.allowed_client_ids, [])
    }
  }
  auth_users = {
    for user_name, user in try(local.application_configuration.auth_configuration.users, {}) : user_name => {
      enabled   = try(user.enabled, true)
      role_name = user.role_name
    }
  }
  auth_system_principals = {
    for principal_name, principal in try(local.application_configuration.auth_configuration.system_principals, {}) : principal_name => {
      enabled   = try(principal.enabled, true)
      role_name = principal.role_name
    }
  }
  transfer_clients = {
    for client_id, client in try(local.application_configuration.transfer_clients, {}) : client_id => {
      enabled               = try(client.enabled, true)
      key_prefix            = try(client.key_prefix, null)
      max_upload_size_bytes = try(client.max_upload_size_bytes, 107374182400)
      allowed_content_types = try(client.allowed_content_types, [])
    }
  }

  observability_configuration = {
    api_gateway_latency_threshold_ms       = try(local.application_configuration.observability_configuration.api_gateway_latency_threshold_ms, 5000)
    api_gateway_latency_evaluation_periods = try(local.application_configuration.observability_configuration.api_gateway_latency_evaluation_periods, 2)
    lambda_duration_threshold_ms           = try(local.application_configuration.observability_configuration.lambda_duration_threshold_ms, 2000)
    lambda_duration_evaluation_periods     = try(local.application_configuration.observability_configuration.lambda_duration_evaluation_periods, 2)
  }

  cloudwatch_alarm_actions_high_priority = var.alarm_topic_arns.high_priority != null ? [var.alarm_topic_arns.high_priority] : []
  cloudwatch_alarm_actions_low_priority  = var.alarm_topic_arns.low_priority != null ? [var.alarm_topic_arns.low_priority] : []

  cloudwatch_lambda_alarms = {
    "upload-ticket" = {
      alarm_name_prefix = "${local.resource_name_prefix}-upload-ticket"
      description       = "Upload ticket Lambda"
      function_name     = module.lambda_upload_ticket.lambda_function_name
    }
    "authorizer" = {
      alarm_name_prefix = "${local.resource_name_prefix}-authorizer"
      description       = "Request authorizer Lambda"
      function_name     = module.lambda_api_authorizer.lambda_function_name
    }
    "docs" = {
      alarm_name_prefix = "${local.resource_name_prefix}-docs"
      description       = "Swagger UI docs Lambda"
      function_name     = module.lambda_api_docs.lambda_function_name
    }
  }
}
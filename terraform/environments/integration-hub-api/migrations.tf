moved {
  from = aws_cloudwatch_log_group.api_access
  to   = module.integration_hub_file_transfer_api.aws_cloudwatch_log_group.api_access
}

moved {
  from = aws_apigatewayv2_api.upload_ticket
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_api.upload_ticket
}

moved {
  from = aws_apigatewayv2_integration.upload_ticket
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_integration.upload_ticket
}

moved {
  from = aws_apigatewayv2_integration.api_docs
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_integration.api_docs
}

moved {
  from = aws_apigatewayv2_authorizer.mft_request
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_authorizer.mft_request
}

moved {
  from = aws_apigatewayv2_route.transfer_tickets
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_route.transfer_tickets
}

moved {
  from = aws_apigatewayv2_route.transfer_ticket_parts
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_route.transfer_ticket_parts
}

moved {
  from = aws_apigatewayv2_route.transfer_ticket_complete
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_route.transfer_ticket_complete
}

moved {
  from = aws_apigatewayv2_route.transfer_ticket_abort
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_route.transfer_ticket_abort
}

moved {
  from = aws_apigatewayv2_route.api_docs
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_route.api_docs
}

moved {
  from = aws_apigatewayv2_route.api_openapi_contract
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_route.api_openapi_contract
}

moved {
  from = aws_apigatewayv2_stage.default
  to   = module.integration_hub_file_transfer_api.aws_apigatewayv2_stage.default
}

moved {
  from = aws_lambda_permission.allow_api_gateway_upload_ticket
  to   = module.integration_hub_file_transfer_api.aws_lambda_permission.allow_api_gateway_upload_ticket
}

moved {
  from = aws_lambda_permission.allow_api_gateway_authorizer
  to   = module.integration_hub_file_transfer_api.aws_lambda_permission.allow_api_gateway_authorizer
}

moved {
  from = aws_lambda_permission.allow_api_gateway_api_docs
  to   = module.integration_hub_file_transfer_api.aws_lambda_permission.allow_api_gateway_api_docs
}

moved {
  from = module.lambda_upload_ticket
  to   = module.integration_hub_file_transfer_api.module.lambda_upload_ticket
}

moved {
  from = module.lambda_api_authorizer
  to   = module.integration_hub_file_transfer_api.module.lambda_api_authorizer
}

moved {
  from = module.lambda_api_docs
  to   = module.integration_hub_file_transfer_api.module.lambda_api_docs
}

moved {
  from = module.dynamodb_transfer_clients
  to   = module.integration_hub_file_transfer_api.module.dynamodb_transfer_clients
}

moved {
  from = module.dynamodb_auth_roles
  to   = module.integration_hub_file_transfer_api.module.dynamodb_auth_roles
}

moved {
  from = module.dynamodb_auth_principals
  to   = module.integration_hub_file_transfer_api.module.dynamodb_auth_principals
}

moved {
  from = module.dynamodb_multipart_uploads
  to   = module.integration_hub_file_transfer_api.module.dynamodb_multipart_uploads
}

moved {
  from = aws_dynamodb_table_item.transfer_client
  to   = module.integration_hub_file_transfer_api.aws_dynamodb_table_item.transfer_client
}

moved {
  from = aws_dynamodb_table_item.auth_role
  to   = module.integration_hub_file_transfer_api.aws_dynamodb_table_item.auth_role
}

moved {
  from = aws_dynamodb_table_item.auth_user_principal
  to   = module.integration_hub_file_transfer_api.aws_dynamodb_table_item.auth_user_principal
}

moved {
  from = aws_dynamodb_table_item.auth_system_principal
  to   = module.integration_hub_file_transfer_api.aws_dynamodb_table_item.auth_system_principal
}

moved {
  from = module.api_user_credentials_secret
  to   = module.integration_hub_file_transfer_api.module.api_user_credentials_secret
}

moved {
  from = module.api_system_bearer_token_secret
  to   = module.integration_hub_file_transfer_api.module.api_system_bearer_token_secret
}

moved {
  from = module.api_docs_basic_auth_secret
  to   = module.integration_hub_file_transfer_api.module.api_docs_basic_auth_secret
}

moved {
  from = module.kms_cloudwatch_logs
  to   = module.integration_hub_file_transfer_api.module.kms_cloudwatch_logs
}

moved {
  from = module.cloudwatch_api_gateway_5xx
  to   = module.integration_hub_file_transfer_api.module.cloudwatch_api_gateway_5xx
}

moved {
  from = module.cloudwatch_api_gateway_latency
  to   = module.integration_hub_file_transfer_api.module.cloudwatch_api_gateway_latency
}

moved {
  from = module.cloudwatch_lambda_errors
  to   = module.integration_hub_file_transfer_api.module.cloudwatch_lambda_errors
}

moved {
  from = module.cloudwatch_lambda_throttles
  to   = module.integration_hub_file_transfer_api.module.cloudwatch_lambda_throttles
}

moved {
  from = module.cloudwatch_lambda_duration
  to   = module.integration_hub_file_transfer_api.module.cloudwatch_lambda_duration
}

moved {
  from = aws_cloudwatch_dashboard.api_platform
  to   = module.integration_hub_file_transfer_api.aws_cloudwatch_dashboard.api_platform
}

moved {
  from = data.aws_iam_policy_document.app_deploy_assume_role
  to   = module.integration_hub_file_transfer_api.data.aws_iam_policy_document.app_deploy_assume_role
}

moved {
  from = data.aws_iam_policy_document.app_deploy
  to   = module.integration_hub_file_transfer_api.data.aws_iam_policy_document.app_deploy
}

moved {
  from = aws_iam_role.app_deploy
  to   = module.integration_hub_file_transfer_api.module.app_deploy.aws_iam_role.this[0]
}

moved {
  from = aws_iam_role_policy.app_deploy
  to   = module.integration_hub_file_transfer_api.module.app_deploy.aws_iam_role_policy.inline[0]
}
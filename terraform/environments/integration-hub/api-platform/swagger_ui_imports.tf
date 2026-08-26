locals {
  swagger_ui_partial_apply_resources = {
    secret_arn        = "arn:aws:secretsmanager:eu-west-2:508564776517:secret:integration-hub-api-platform-development-docs-basic-auth-cEanY5"
    secret_version_id = "terraform-20260623151830736200000002"
  }
}

# Adopt resources created during the partial Swagger UI apply in development.
import {
  for_each = local.environment == "development" ? { docs = true } : {}
  to       = module.api_docs_basic_auth_secret.aws_secretsmanager_secret.this[0]
  id       = local.swagger_ui_partial_apply_resources.secret_arn
}

import {
  for_each = local.environment == "development" ? { docs = true } : {}
  to       = module.api_docs_basic_auth_secret.aws_secretsmanager_secret_version.ignore_changes[0]
  id       = "${local.swagger_ui_partial_apply_resources.secret_arn}|${local.swagger_ui_partial_apply_resources.secret_version_id}"
}

import {
  for_each = local.environment == "development" ? { docs = true } : {}
  to       = module.lambda_api_docs.aws_iam_role.lambda[0]
  id       = "${local.application_name}-${local.component_name}-docs"
}

import {
  for_each = local.environment == "development" ? { docs = true } : {}
  to       = module.lambda_api_docs.aws_iam_role_policy.additional_inline[0]
  id       = "${local.application_name}-${local.component_name}-docs:${local.application_name}-${local.component_name}-docs-inline"
}

import {
  for_each = local.environment == "development" ? { docs = true } : {}
  to       = module.lambda_api_docs.aws_iam_role_policy.logs[0]
  id       = "${local.application_name}-${local.component_name}-docs:${local.application_name}-${local.component_name}-docs-logs"
}

import {
  for_each = local.environment == "development" ? { docs = true } : {}
  to       = module.lambda_api_docs.aws_cloudwatch_log_group.lambda[0]
  id       = "/aws/lambda/${local.application_name}-${local.component_name}-docs"
}

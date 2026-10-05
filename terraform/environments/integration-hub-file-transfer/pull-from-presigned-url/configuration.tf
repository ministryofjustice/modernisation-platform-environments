module "pickup_configuration" {
  source      = "../modules/authenticated-pickup-configuration"
  environment = local.environment
}

module "dispatch_configuration" {
  source      = "../modules/file-dispatch-configuration"
  environment = local.environment
}

locals {
  pattern_name       = "${local.application_name}-${local.component_name}"
  pickup_bucket_name = "${local.application_name}-pickup-${local.environment}-${data.aws_caller_identity.current.account_id}"
  pickup_sso         = lookup(var.pickup_sso_by_environment, local.environment, null)
  recipients         = module.pickup_configuration.recipients
  portal_url         = aws_apigatewayv2_api.pickup.api_endpoint
  routes = { for id, recipient in local.recipients : data.aws_secretsmanager_secret.dispatch[id].arn => {
    recipient_id       = id
    prefix             = recipient.prefix
    webhook_secret_arn = aws_secretsmanager_secret.webhook[id].arn
  } }
}

data "aws_cloudwatch_event_bus" "file_transfer" { name = local.application_name }
data "aws_kms_key" "logs" { key_id = "alias/logs/${local.application_name}-${local.environment}" }
data "aws_kms_key" "secrets" { key_id = "alias/secrets/${local.application_name}-${local.environment}" }

data "aws_secretsmanager_secret" "dispatch" {
  for_each = local.recipients
  name     = "${local.application_name}/file-dispatch/${each.value.prefix}"
  lifecycle {
    precondition {
      condition     = contains(keys(module.dispatch_configuration.entries), each.value.prefix)
      error_message = "Each pickup prefix must have an existing shared dispatch entry; deploy its secret from root first."
    }
  }
}

# Populate {"url":"https://hooks.slack.com/services/..."} outside Terraform.
resource "aws_secretsmanager_secret" "webhook" {
  #checkov:skip=CKV2_AWS_57:Externally issued Slack webhook; revoke/reissue in Slack and replace this secret. No AWS-managed rotation is available.
  for_each                = local.recipients
  name                    = "${local.application_name}/slack-pickup/${each.key}"
  description             = "Slack incoming webhook for authenticated pickup notifications"
  kms_key_id              = data.aws_kms_key.secrets.arn
  recovery_window_in_days = 30
  tags                    = local.tags
}

module "dynamodb_notifications" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source                             = "terraform-aws-modules/dynamodb-table/aws"
  version                            = "5.5.0"
  name                               = local.pattern_name
  hash_key                           = "id"
  attributes                         = [{ name = "id", type = "S" }]
  billing_mode                       = "PAY_PER_REQUEST"
  ttl_enabled                        = true
  ttl_attribute_name                 = "expiresAt"
  point_in_time_recovery_enabled     = true
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = module.kms_notifications_pipeline.key_arn
  deletion_protection_enabled        = true
  tags                               = local.tags
}

# A reviewed organisational OIDC application is required before recipients can be enabled.
variable "pickup_sso_by_environment" {
  description = "Public OIDC client using authorization code + S256 PKCE and JWT access tokens. No client secret."
  type = map(object({
    issuer                 = string
    audience               = string
    client_id              = string
    authorization_endpoint = string
    token_endpoint         = string
    download_scope         = string
    groups_claim           = optional(string, "groups")
  }))
  default = {}
  validation {
    condition = alltrue([for environment, sso in var.pickup_sso_by_environment :
      contains(["development", "test", "preproduction", "production"], environment) &&
      alltrue([for url in [sso.issuer, sso.authorization_endpoint, sso.token_endpoint] : can(regex("^https://[^/?#]+[^#]*$", url))]) &&
      length(sso.audience) > 0 && length(sso.client_id) > 0 &&
      can(regex("^[^ ]+$", sso.download_scope)) &&
      !contains(["openid", "email", "profile"], sso.download_scope)
    ])
    error_message = "Use HTTPS OIDC endpoints, explicit audience/client and a dedicated API access-token scope."
  }
}

module "pickup_configuration" {
  source      = "../modules/authenticated-pickup-configuration"
  environment = local.environment
}

module "dispatch_configuration" {
  source      = "../modules/file-dispatch-configuration"
  environment = local.environment
}

locals {
  pattern_name = "${local.application_name}-${local.component_name}"
  recipients   = module.pickup_configuration.recipients
  portal_url   = local.is-production ? "https://web.file-transfer.service.justice.gov.uk" : "https://web.${local.environment}.file-transfer.service.justice.gov.uk"
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

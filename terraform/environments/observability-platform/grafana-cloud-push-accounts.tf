# Grafana Cloud write tokens, one per tenant AWS account that pushes metrics, logs or traces (the
# account's `push` setting in grafana-cloud-tenant-environment-configurations.tf).
#
# The account's OTLP gateway (deployed by the tenant module) pushes to the stack's OTLP endpoint with
# the token. Each account's token is written, with the endpoint and username, to the
# `grafana-cloud/push/<account ID>` secret in this account, encrypted with a customer managed KMS key
# and shared with that account's gateway execution role through the secret and key policies, as for
# PDC (grafana-cloud-pdc-accounts.tf). The tenant module derives the secret name from the account ID,
# so it must not change. Cross-account access also needs an identity policy on the gateway execution
# role (tenant module).
#
# A write token can't be limited to labels: it can write data with any account's `cloud_account_id`,
# which the shared data sources' label-based access control rules rely on. Only the gateway may hold
# it, and the gateway must set `cloud.account.id` to its own account, overwriting what apps send.

locals {
  # Must match the name of the OTLP gateway execution role created by the tenant module.
  gc_otlp_gateway_execution_role_name = "grafana-otlp-gateway-execution"

  # Access policy scope for each signal
  gc_push_scopes = {
    metrics = "metrics:write"
    logs    = "logs:write"
    traces  = "traces:write"
  }

  # Account name => signals it pushes, for the tenant accounts that push to Grafana Cloud
  gc_push_signals = {
    for account_name, account in local.gc_accounts :
    account_name => sort([for signal, enabled in account.push : signal if enabled])
    if anytrue(values(account.push))
  }

  # Account name => account ID
  gc_push_accounts = {
    for account_name in keys(local.gc_push_signals) : account_name => local.all_account_ids[account_name]
  }

  # Trust the tenant account, restricted to the gateway execution role, as for PDC
  gc_otlp_gateway_principal_arns = {
    for account_name, account_id in local.gc_push_accounts :
    account_name => "arn:aws:iam::${account_id}:role/${local.gc_otlp_gateway_execution_role_name}"
  }
}

# Write only, for the signals the account pushes, and only to this environment's stack. Names are
# unique per organisation, as for PDC.
resource "grafana_cloud_access_policy" "push" {
  for_each = local.gc_push_signals
  provider = grafana.cloud

  name         = "${grafana_cloud_stack.observability_platform.slug}-${each.key}-push"
  display_name = "${each.key} (${grafana_cloud_stack.observability_platform.slug}) push"
  region       = grafana_cloud_stack.observability_platform.region_slug
  scopes       = [for signal in each.value : local.gc_push_scopes[signal]]

  realm {
    type       = "stack"
    identifier = grafana_cloud_stack.observability_platform.id
  }
}

# No expiry, as for the PDC tokens. Replace the token to rotate it.
resource "grafana_cloud_access_policy_token" "push" {
  for_each = local.gc_push_signals
  provider = grafana.cloud

  name             = "${grafana_cloud_access_policy.push[each.key].name}-gateway"
  display_name     = "${each.key} (${grafana_cloud_stack.observability_platform.slug}) gateway"
  access_policy_id = grafana_cloud_access_policy.push[each.key].policy_id
  region           = grafana_cloud_access_policy.push[each.key].region
}

data "aws_iam_policy_document" "gc_push_token_kms" {
  for_each = local.gc_push_accounts

  statement {
    sid       = "EnableAccountAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowTenantGatewayToDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${each.value}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [local.gc_otlp_gateway_principal_arns[each.key]]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "gc_push_token" {
  for_each = local.gc_push_accounts

  description         = "Encrypts the Grafana Cloud push token for ${each.key}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.gc_push_token_kms[each.key].json
}

resource "aws_kms_alias" "gc_push_token" {
  for_each = local.gc_push_accounts

  name          = "alias/grafana-cloud-push-${each.key}"
  target_key_id = aws_kms_key.gc_push_token[each.key].key_id
}

resource "aws_secretsmanager_secret" "gc_push_token" {
  #checkov:skip=CKV2_AWS_57:Token is issued by Grafana Cloud and rotated via Terraform
  for_each = local.gc_push_accounts

  name       = "grafana-cloud/push/${each.value}"
  kms_key_id = aws_kms_key.gc_push_token[each.key].arn
}

# OTLP over HTTP with basic auth: the username is the stack ID and the password is the token
resource "aws_secretsmanager_secret_version" "gc_push_token" {
  for_each = local.gc_push_accounts

  secret_id = aws_secretsmanager_secret.gc_push_token[each.key].id
  secret_string = jsonencode({
    otlp_endpoint = grafana_cloud_stack.observability_platform.otlp_url
    username      = grafana_cloud_stack.observability_platform.id
    token         = grafana_cloud_access_policy_token.push[each.key].token
    signals       = local.gc_push_signals[each.key]
  })
}

data "aws_iam_policy_document" "gc_push_token_secret" {
  for_each = local.gc_push_accounts

  statement {
    sid       = "AllowTenantGatewayToReadToken"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${each.value}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [local.gc_otlp_gateway_principal_arns[each.key]]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "gc_push_token" {
  for_each = local.gc_push_accounts

  secret_arn = aws_secretsmanager_secret.gc_push_token[each.key].arn
  policy     = data.aws_iam_policy_document.gc_push_token_secret[each.key].json
}

output "grafana_cloud_push_accounts" {
  description = "Per-account push signals and token secret ARN, keyed by tenant AWS account name."
  # Account IDs come from the sensitive environment_management secret.
  sensitive = true
  # Null rather than empty when no account pushes, so those environments plan no changes
  value = length(local.gc_push_signals) > 0 ? {
    for account_name, account_id in local.gc_push_accounts : account_name => {
      account_id       = account_id
      signals          = local.gc_push_signals[account_name]
      token_secret_arn = aws_secretsmanager_secret.gc_push_token[account_name].arn
    }
  } : null
}

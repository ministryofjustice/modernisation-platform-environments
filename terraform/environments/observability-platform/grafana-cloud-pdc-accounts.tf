# Private Data Source Connect (PDC) networks and agent tokens, one per tenant AWS account.
#
# The PDC agents run in the tenant accounts (deployed by the tenant module). PDC load-balances across
# every agent in a network, so every agent must reach the same targets. A tenant's accounts sit in
# different VPCs, so each account gets its own network.
#
# Each account's token is written to the `grafana-cloud/pdc/<account ID>` secret in this account,
# encrypted with a customer managed KMS key, and shared with that account's agent execution role
# through the secret and key policies. The tenant module derives the secret name from the account ID,
# so it must not change. Cross-account access also needs an identity policy on the agent execution
# role (tenant module).

locals {
  # Must match the name of the agent execution role created by the tenant module.
  gc_pdc_agent_execution_role_name = "grafana-pdc-agent-execution"

  # Account name => account ID, for the tenant accounts that run PDC agents. `pdc_enabled` must
  # match the tenant module's `grafana_cloud.pdc_agent.enabled`; both are opt-in, defaulting to false.
  gc_pdc_accounts = {
    for account_name, account in local.gc_accounts :
    account_name => local.all_account_ids[account_name] if account.pdc_enabled
  }

  # Trust the tenant account, restricted to the agent execution role. The role is matched by ARN in a
  # condition rather than named as the principal, so these policies can be applied before the role exists.
  gc_pdc_agent_principal_arns = {
    for account_name, account_id in local.gc_pdc_accounts :
    account_name => "arn:aws:iam::${account_id}:role/${local.gc_pdc_agent_execution_role_name}"
  }

  # PDC networks and tokens are Grafana Cloud access policies, whose names are unique per organisation
  # (1-255 characters: a-z, 0-9, hyphens and underscores). Prefix with the stack slug, as the
  # development and production stacks may share an organisation.
  gc_pdc_network_names = {
    for account_name, _ in local.gc_pdc_accounts :
    account_name => "${grafana_cloud_stack.observability_platform.slug}-${account_name}"
  }
}

resource "grafana_cloud_private_data_source_connect_network" "account" {
  for_each = local.gc_pdc_accounts
  provider = grafana.cloud

  name             = local.gc_pdc_network_names[each.key]
  display_name     = "${each.key} (${grafana_cloud_stack.observability_platform.slug})"
  region           = grafana_cloud_stack.observability_platform.region_slug
  stack_identifier = grafana_cloud_stack.observability_platform.id
}

resource "grafana_cloud_private_data_source_connect_network_token" "account" {
  for_each = local.gc_pdc_accounts
  provider = grafana.cloud

  name           = "${local.gc_pdc_network_names[each.key]}-agent"
  display_name   = "${each.key} (${grafana_cloud_stack.observability_platform.slug}) agents"
  pdc_network_id = grafana_cloud_private_data_source_connect_network.account[each.key].pdc_network_id
  region         = grafana_cloud_private_data_source_connect_network.account[each.key].region

  lifecycle {
    # Replacing this resource revokes the token before agents have read its replacement.
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "gc_pdc_token_kms" {
  for_each = local.gc_pdc_accounts

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
    sid       = "AllowTenantAgentToDecrypt"
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
      values   = [local.gc_pdc_agent_principal_arns[each.key]]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "gc_pdc_token" {
  for_each = local.gc_pdc_accounts

  description         = "Encrypts the Grafana Cloud PDC agent token for ${each.key}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.gc_pdc_token_kms[each.key].json
}

resource "aws_kms_alias" "gc_pdc_token" {
  for_each = local.gc_pdc_accounts

  name          = "alias/grafana-cloud-pdc-${each.key}"
  target_key_id = aws_kms_key.gc_pdc_token[each.key].key_id
}

resource "aws_secretsmanager_secret" "gc_pdc_token" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation awaits the tested PDC rotator; see docs/grafana-cloud/pdc-token-rotation.md
  for_each = local.gc_pdc_accounts

  name       = "grafana-cloud/pdc/${each.value}"
  kms_key_id = aws_kms_key.gc_pdc_token[each.key].arn
  tags       = local.gc_pdc_rotation_tags[each.key]
}

resource "aws_secretsmanager_secret_version" "gc_pdc_token" {
  for_each = local.gc_pdc_accounts

  secret_id     = aws_secretsmanager_secret.gc_pdc_token[each.key].id
  secret_string = grafana_cloud_private_data_source_connect_network_token.account[each.key].token

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "gc_pdc_token_secret" {
  for_each = local.gc_pdc_accounts

  statement {
    sid       = "AllowTenantAgentToReadToken"
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
      values   = [local.gc_pdc_agent_principal_arns[each.key]]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "gc_pdc_token" {
  for_each = local.gc_pdc_accounts

  secret_arn = aws_secretsmanager_secret.gc_pdc_token[each.key].arn
  policy     = data.aws_iam_policy_document.gc_pdc_token_secret[each.key].json
}

output "grafana_cloud_pdc_accounts" {
  description = "Per-account PDC network ID and token secret ARN, keyed by tenant AWS account name."
  # Account IDs come from the sensitive environment_management secret.
  sensitive = true
  value = {
    for account_name, account_id in local.gc_pdc_accounts : account_name => {
      account_id       = account_id
      pdc_network_id   = grafana_cloud_private_data_source_connect_network.account[account_name].pdc_network_id
      token_secret_arn = aws_secretsmanager_secret.gc_pdc_token[account_name].arn
    }
  }
}

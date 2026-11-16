# Private Data Source Connect (PDC) networks and agent tokens, one per Grafana Cloud tenant.
#
# The PDC agents run in the tenant accounts (deployed by the tenant module). Each tenant's token is
# written to a Secrets Manager secret in this account, encrypted with a customer managed KMS key, and
# shared with the tenant's agent execution role through the secret and key policies.
# Cross-account access also needs an identity policy on the tenant's execution role (tenant module).

locals {
  # Must match the name of the agent execution role created by the tenant module.
  gc_pdc_agent_execution_role_name = "grafana-pdc-agent-execution"

  # Tenant => account IDs of the accounts that run PDC agents.
  gc_pdc_tenants = {
    for tenant_name, tenant in local.environment_configuration_gc.tenant_configuration :
    tenant_name => [
      for account_name, account in tenant.aws_accounts :
      local.all_account_ids[account_name] if lookup(account, "pdc_enabled", false)
    ]
    if anytrue([for account in tenant.aws_accounts : lookup(account, "pdc_enabled", false)])
  }

  # Trust the tenant accounts, restricted to the agent execution role. The role is matched by ARN in a
  # condition rather than named as the principal, so these policies can be applied before the role exists.
  gc_pdc_agent_principal_arns = {
    for tenant_name, account_ids in local.gc_pdc_tenants :
    tenant_name => [for account_id in account_ids : "arn:aws:iam::${account_id}:role/${local.gc_pdc_agent_execution_role_name}"]
  }
}

resource "grafana_cloud_private_data_source_connect_network" "tenant" {
  for_each = local.gc_pdc_tenants
  provider = grafana.cloud

  name             = "${each.key}-${local.environment}"
  display_name     = "${each.key} ${local.environment}"
  region           = grafana_cloud_stack.observability_platform.region_slug
  stack_identifier = grafana_cloud_stack.observability_platform.id
}

resource "grafana_cloud_private_data_source_connect_network_token" "tenant" {
  for_each = local.gc_pdc_tenants
  provider = grafana.cloud

  name           = "${each.key}-${local.environment}-agent"
  display_name   = "${each.key} ${local.environment} agents"
  pdc_network_id = grafana_cloud_private_data_source_connect_network.tenant[each.key].pdc_network_id
  region         = grafana_cloud_private_data_source_connect_network.tenant[each.key].region
}

data "aws_iam_policy_document" "gc_pdc_token_kms" {
  for_each = local.gc_pdc_tenants

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
    sid       = "AllowTenantAgentsToDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [for account_id in each.value : "arn:aws:iam::${account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = local.gc_pdc_agent_principal_arns[each.key]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "gc_pdc_token" {
  for_each = local.gc_pdc_tenants

  description         = "Encrypts the Grafana Cloud PDC agent token for ${each.key}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.gc_pdc_token_kms[each.key].json
}

resource "aws_kms_alias" "gc_pdc_token" {
  for_each = local.gc_pdc_tenants

  name          = "alias/grafana-cloud-pdc-${each.key}"
  target_key_id = aws_kms_key.gc_pdc_token[each.key].key_id
}

resource "aws_secretsmanager_secret" "gc_pdc_token" {
  #checkov:skip=CKV2_AWS_57:Token is issued by Grafana Cloud and rotated via Terraform
  for_each = local.gc_pdc_tenants

  name       = "grafana-cloud/pdc/${each.key}"
  kms_key_id = aws_kms_key.gc_pdc_token[each.key].arn
}

resource "aws_secretsmanager_secret_version" "gc_pdc_token" {
  for_each = local.gc_pdc_tenants

  secret_id     = aws_secretsmanager_secret.gc_pdc_token[each.key].id
  secret_string = grafana_cloud_private_data_source_connect_network_token.tenant[each.key].token
}

data "aws_iam_policy_document" "gc_pdc_token_secret" {
  for_each = local.gc_pdc_tenants

  statement {
    sid       = "AllowTenantAgentsToReadToken"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [for account_id in each.value : "arn:aws:iam::${account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = local.gc_pdc_agent_principal_arns[each.key]
    }
  }
}

resource "aws_secretsmanager_secret_policy" "gc_pdc_token" {
  for_each = local.gc_pdc_tenants

  secret_arn = aws_secretsmanager_secret.gc_pdc_token[each.key].arn
  policy     = data.aws_iam_policy_document.gc_pdc_token_secret[each.key].json
}

output "grafana_cloud_pdc_tenants" {
  description = "Per-tenant PDC network ID and token secret ARN, for the tenant module's pdc agent inputs."
  value = {
    for tenant_name, _ in local.gc_pdc_tenants : tenant_name => {
      pdc_network_id   = grafana_cloud_private_data_source_connect_network.tenant[tenant_name].pdc_network_id
      token_secret_arn = aws_secretsmanager_secret.gc_pdc_token[tenant_name].arn
    }
  }
}

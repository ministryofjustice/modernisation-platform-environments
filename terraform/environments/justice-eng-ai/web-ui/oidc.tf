
# Microsoft Entra ID OIDC wiring.
#
# Decision for this MVP: the UI container performs its own Entra OIDC
# handshake (var.enable_in_app_oidc), not the ALB's ``authenticate-oidc``
# listener action. The ALB-owned path is kept available behind
# `local.oidc_wired` in case that decision changes later, but the two are
# mutually exclusive -- running both at once would double-authenticate.
locals {
  # Only the development account has had its Entra callback URIs reviewed
  # and secrets populated so far; production needs a conscious re-review
  # before this flips on there too (see var.enable_in_app_oidc default).
  oidc_auto_enabled_environment = local.environment == "development"

  in_app_oidc_enabled = var.enable_in_app_oidc && var.enable_oidc_auth && var.oidc_configured && local.oidc_auto_enabled_environment
  in_app_oidc_count   = local.in_app_oidc_enabled ? 1 : 0

  oidc_wired       = var.enable_oidc_auth && var.oidc_configured && !var.enable_in_app_oidc && local.oidc_auto_enabled_environment
  oidc_wired_count = local.oidc_wired ? 1 : 0
}

# ---------- Entra OIDC secrets ----------
#
# Created empty; populate out-of-band via `aws secretsmanager
# put-secret-value` after apply (mirrors the GitHub App secrets in
# secrets.tf -- Terraform never sees the plaintext). Consumed by the UI task
# (ecs.tf's `secrets` block) when in-app OIDC is enabled, or by the ALB
# listener (load-balancer.tf) if the ALB-owned path is wired instead.
# Also shared with Forge Journey Lab (forge-journey-lab.tf) -- both use the
# same Entra app registration, so there is only one set of secrets to
# populate, not one per component.
locals {
  entra_oidc_secrets_needed = var.enable_oidc_auth || local.forge_internal
}

resource "aws_secretsmanager_secret" "entra_oidc_tenant_id" {
  count = local.entra_oidc_secrets_needed ? 1 : 0

  # checkov:skip=CKV2_AWS_57:Value is owned by the Entra app registration;
  # rotation is coordinated on the IdP side, not via Secrets Manager's
  # scheduled rotation.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is
  # proportionate for this prototype migration.
  name                    = "${local.application_name}-ui/entra-oidc-tenant-id"
  description             = "Microsoft Entra tenant ID, shared by the builder UI and Forge Journey Lab. Populate manually after apply."
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret" "entra_oidc_client_id" {
  count = local.entra_oidc_secrets_needed ? 1 : 0

  # checkov:skip=CKV2_AWS_57:Value is owned by the Entra app registration;
  # rotation is coordinated on the IdP side, not via Secrets Manager's
  # scheduled rotation.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is
  # proportionate for this prototype migration.
  name                    = "${local.application_name}-ui/entra-oidc-client-id"
  description             = "Microsoft Entra application (client) ID, shared by the builder UI and Forge Journey Lab. Populate manually after apply."
  recovery_window_in_days = 7
  tags                    = local.tags
}

resource "aws_secretsmanager_secret" "entra_oidc_client_secret" {
  count = local.entra_oidc_secrets_needed ? 1 : 0

  # checkov:skip=CKV2_AWS_57:Value is owned by the Entra app registration;
  # rotation is coordinated on the IdP side, not via Secrets Manager's
  # scheduled rotation.
  # checkov:skip=CKV_AWS_149:AWS-managed Secrets Manager encryption is
  # proportionate for this prototype migration.
  name                    = "${local.application_name}-ui/entra-oidc-client-secret"
  description             = "Microsoft Entra application client secret, shared by the builder UI and Forge Journey Lab. Populate manually after apply."
  recovery_window_in_days = 7
  tags                    = local.tags
}

# Only read back when the ALB owns the OIDC flow -- the in-app path reads
# the secrets itself at task-start via the `secrets` block in ecs.tf.
data "aws_secretsmanager_secret_version" "entra_oidc_tenant_id" {
  count     = local.oidc_wired_count
  secret_id = aws_secretsmanager_secret.entra_oidc_tenant_id[0].id
}

data "aws_secretsmanager_secret_version" "entra_oidc_client_id" {
  count     = local.oidc_wired_count
  secret_id = aws_secretsmanager_secret.entra_oidc_client_id[0].id
}

data "aws_secretsmanager_secret_version" "entra_oidc_client_secret" {
  count     = local.oidc_wired_count
  secret_id = aws_secretsmanager_secret.entra_oidc_client_secret[0].id
}

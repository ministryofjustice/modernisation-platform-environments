
# Microsoft Entra ID OIDC wiring.
#
# Two mutually exclusive ways to sign users in to the builder UI -- running
# both at once would double-authenticate:
#
#   "in-app" -- the UI container performs its own Entra OIDC handshake
#               (MPAPB_ENTRA_ENABLED=true); the ALB forwards plainly.
#   "alb"    -- the ALB's ``authenticate-oidc`` listener action signs the
#               user in; the UI verifies the ALB-signed X-Amzn-Oidc-Data
#               token on every request (MPAPB_TRUST_ALB_OIDC=true plus
#               MPAPB_ALB_SIGNER_ARN, see ecs.tf).
#
# Chosen per account via ``builder_auth_mode`` in application_variables.json
# so development can move to "alb" ahead of production. Accounts without the
# key fall back to var.enable_in_app_oidc (true -> "in-app").
#
# Forge Journey Lab is NOT covered by the ALB action yet: its host-header
# listener rule (forge-journey-lab.tf) forwards without authenticating, so
# Forge keeps its own in-app Entra login in both modes.
locals {
  builder_auth_mode = try(
    local.application_data.accounts[local.environment].builder_auth_mode,
    var.enable_in_app_oidc ? "in-app" : "alb",
  )
  # Validated by the precondition on aws_lb_listener.https (load-balancer.tf).
  in_app_oidc_requested = local.builder_auth_mode == "in-app"

  # Both accounts have their in-app Entra callback URIs
  # (https://<host>/auth/callback) registered and secrets populated.
  # Before switching an account to "alb", ALSO register the ALB callback
  # https://<builder_hostname>/oauth2/idpresponse on the same Entra app
  # registration -- otherwise sign-in fails at Entra with a redirect URI
  # mismatch.
  in_app_oidc_enabled = local.in_app_oidc_requested && var.enable_oidc_auth && var.oidc_configured
  in_app_oidc_count   = local.in_app_oidc_enabled ? 1 : 0

  oidc_wired       = var.enable_oidc_auth && var.oidc_configured && !local.in_app_oidc_requested
  oidc_wired_count = local.oidc_wired ? 1 : 0
  alb_group_authorization_enabled = try(
    local.application_data.accounts[local.environment].alb_group_authorization_enabled,
    false,
  )
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

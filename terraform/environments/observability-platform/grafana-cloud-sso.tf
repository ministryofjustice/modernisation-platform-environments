# GitHub SSO for the Grafana Cloud stack. Access is driven by membership of GitHub teams in the
# ministryofjustice organisation. The GitHub OAuth app is created manually (callback
# https://<stack>.grafana.net/login/github, scope read:org, approved by the organisation) and its
# credentials are stored in Secrets Manager.

resource "grafana_sso_settings" "github" {
  provider = grafana.stack

  provider_name = "github"

  oauth2_settings {
    name                  = "GitHub"
    client_id             = data.aws_secretsmanager_secret_version.grafana_cloud_github_oauth_client_id.secret_string
    client_secret         = data.aws_secretsmanager_secret_version.grafana_cloud_github_oauth_client_secret.secret_string
    allowed_organizations = "ministryofjustice"
    auto_login            = false
    allow_sign_up         = true
    # GitHub teams are exposed to the mapping as groups in the form @org/team-slug
    role_attribute_path        = "contains(groups[*], '@ministryofjustice/observability-platform') && 'Admin' || 'Viewer'"
    role_attribute_strict      = false
    skip_org_role_sync         = false
    allow_assign_grafana_admin = false
    # Numeric GitHub team_ids gating is not set yet; see open questions in the PR
  }
}

# One Grafana team per Grafana Cloud tenant that has a GitHub team
module "grafana_cloud_team" {
  for_each = {
    for name, tenant in local.environment_configuration_gc.tenant_configuration :
    name => tenant if lookup(tenant, "github_team", null) != null
  }
  source = "./modules/grafana-cloud/team"

  providers = {
    grafana = grafana.stack
  }

  name        = each.key
  github_team = each.value.github_team
  # Data sources are added here as tenants' Grafana Cloud data sources are created
  data_source_uids = {}
}

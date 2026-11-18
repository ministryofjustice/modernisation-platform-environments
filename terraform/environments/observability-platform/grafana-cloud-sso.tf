# GitHub SSO for the Grafana Cloud stack. Access is driven by membership of GitHub teams in the
# ministryofjustice organisation. The GitHub OAuth app is created manually (callback
# https://<stack>.grafana.net/login/github, scope read:org, approved by the organisation) and its
# credentials are stored in Secrets Manager.

locals {
  gc_platform_github_team = "observability-platform"

  # Admin team plus every tenant team in the Grafana Cloud tenant configuration
  gc_github_team_slugs = distinct(concat(
    [local.gc_platform_github_team],
    [for tenant in values(local.gc_tenants) : tenant.github_team if tenant.github_team != null]
  ))
}

# GitHub team slug => numeric team ID, for the sign-in gate
data "github_team" "gc" {
  for_each = toset(local.gc_github_team_slugs)

  slug = each.key
}

resource "grafana_sso_settings" "github" {
  provider = grafana.stack

  provider_name = "github"

  oauth2_settings {
    name                  = "GitHub"
    client_id             = data.aws_secretsmanager_secret_version.grafana_cloud_github_oauth_client_id.secret_string
    client_secret         = data.aws_secretsmanager_secret_version.grafana_cloud_github_oauth_client_secret.secret_string
    allowed_organizations = "ministryofjustice"
    # read:org is needed to see org and team membership for the login gate and role mapping
    scopes        = "user:email,read:org"
    auto_login    = false
    allow_sign_up = true
    # GitHub teams are exposed to the mapping as groups in the form @org/team-slug
    role_attribute_path        = "contains(groups[*], '@ministryofjustice/${local.gc_platform_github_team}') && 'Admin' || 'Viewer'"
    role_attribute_strict      = false
    skip_org_role_sync         = false
    allow_assign_grafana_admin = false
    # Only members of the platform team or a tenant team can sign in
    team_ids = join(",", [for team in data.github_team.gc : team.id])
  }
}

# One Grafana team and folder per Grafana Cloud tenant that has a GitHub team. The tenant's AWS
# data sources, and those shared with it, grant Query to the team (grafana-cloud-data-sources.tf).
module "grafana_cloud_team" {
  for_each = {
    for name, tenant in local.gc_tenants : name => tenant if tenant.github_team != null
  }
  source = "./modules/grafana-cloud/team"

  providers = {
    grafana = grafana.stack
  }

  name        = each.key
  github_team = each.value.github_team
}

# GitHub SSO for the Grafana Cloud stack. Access is driven by membership of GitHub teams in the
# ministryofjustice organisation. The GitHub OAuth app is created manually (callback
# https://<stack>.grafana.net/login/github, scope read:org, approved by the organisation) and its
# credentials are stored in Secrets Manager.

locals {
  gc_platform_github_team = "observability-platform"

  # Admin team plus every tenant team in the Grafana Cloud tenant configuration
  gc_github_team_slugs = distinct(concat(
    [local.gc_platform_github_team],
    [for tenant in local.environment_configuration_gc.tenant_configuration : tenant.github_team if lookup(tenant, "github_team", null) != null]
  ))

  # Grafana Cloud data sources managed here, by name. A team can query the data sources whose
  # name starts with "<tenant>-", e.g. "team-1-xray" and "team-1-prometheus" for tenant "team-1".
  gc_data_source_uids = {
    (grafana_data_source.cloud_github.name) = grafana_data_source.cloud_github.uid
  }
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
    auto_login            = false
    allow_sign_up         = true
    # GitHub teams are exposed to the mapping as groups in the form @org/team-slug
    role_attribute_path        = "contains(groups[*], '@ministryofjustice/${local.gc_platform_github_team}') && 'Admin' || 'Viewer'"
    role_attribute_strict      = false
    skip_org_role_sync         = false
    allow_assign_grafana_admin = false
    # Only members of the platform team or a tenant team can sign in
    team_ids = join(",", [for team in data.github_team.gc : team.id])
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
  # Access follows the naming convention: "<tenant>-*" data sources are visible to that tenant's team only
  data_source_uids = {
    for name, uid in local.gc_data_source_uids : name => uid if startswith(name, "${each.key}-")
  }
}

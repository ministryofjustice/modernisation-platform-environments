resource "helm_release" "grafana" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  name             = "grafana"
  repository       = "oci://ghcr.io/grafana-community/helm-charts"
  chart            = "grafana"
  version          = local.environment_configuration.grafana_chart_version
  namespace        = local.environment_configuration.grafana_namespace
  create_namespace = false # namespaces are provisioned in https://github.com/ministryofjustice/cloud-platform-environments/tree/main/namespaces

  values = [
    templatefile("${path.module}/src/helm/values/grafana/values.yml.tftpl", {
      hostname           = local.environment_configuration.monitoring_hostname
      entra_id_tenant_id = local.grafana_entra_id.tenant_id
      # Cloud Platform requires a unique external-dns set-identifier per ingress:
      # <ingress-name>-<namespace>-<cluster-colour>. The chart names the ingress
      # after the release ("grafana") and the live cluster colour is green.
      ingress_set_identifier = "grafana-${local.environment_configuration.grafana_namespace}-green"
      # Resolve each monitored account's ID by name from the Modernisation
      # Platform environment_management map rather than hardcoding it.
      monitored_accounts = [
        for account in local.environment_configuration.grafana_monitored_accounts : merge(account, {
          account_id = local.environment_management.account_ids[account.name]
          # Grafana datasource UIDs are capped at 40 characters, so derive a
          # shorter UID by dropping the shared data-platform- name prefix.
          uid = trimprefix(account.name, "data-platform-")
        })
      ]
    }),
    # Roll the Grafana pods whenever the rendered configuration or the Entra ID
    # credentials change.
    yamlencode({
      podAnnotations = {
        "checksum/config" = sha256(jsonencode({
          secret_version = data.aws_secretsmanager_secret_version.grafana_entra_id[0].version_id
          hostname       = local.environment_configuration.monitoring_hostname
          tenant_id      = local.grafana_entra_id.tenant_id
        }))
      }
    }),
    # Provision dashboards as code, organised into Grafana folders. Each
    # subdirectory of src/helm/dashboards/ becomes a folder (see the
    # grafana_dashboard_* locals); a dashboard switches account at the top via
    # its "Account" data source variable, reusing the per-account CloudWatch data
    # sources from values.yml.tftpl. The chart restarts the pods automatically
    # when a dashboard's contents change.
    yamlencode({
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers  = local.grafana_dashboard_providers
        }
      }
      dashboards = local.grafana_dashboards
    })
  ]

  # OAuth client credentials are injected as environment variables so they are
  # never written into the rendered values file or the stored Helm release
  # manifest in plaintext.
  set_sensitive = [
    {
      name  = "env.GF_AUTH_AZUREAD_CLIENT_ID"
      value = local.grafana_entra_id.client_id
    },
    {
      name  = "env.GF_AUTH_AZUREAD_CLIENT_SECRET"
      value = local.grafana_entra_id.client_secret
    }
  ]
}

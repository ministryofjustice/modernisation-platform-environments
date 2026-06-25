locals {
  # Microsoft Entra ID (Azure AD) OAuth credentials for Grafana. The secret is
  # provisioned with placeholder values in secrets.tf and populated out-of-band,
  # then read back via the data source in data.tf. try() keeps this resolvable in
  # environments where the monitoring stack is disabled and the data source
  # therefore has no instances.
  grafana_entra_id = try(jsondecode(data.aws_secretsmanager_secret_version.grafana_entra_id[0].secret_string), {})

  # Grafana service-account token used by the grafana provider (providers.tf) to
  # manage dashboards and folders as code. Provisioned as a placeholder in
  # secrets.tf and populated out-of-band; try() keeps it resolvable where the
  # monitoring stack is disabled and the data source has no instances.
  grafana_api_token = try(jsondecode(data.aws_secretsmanager_secret_version.grafana_api_token[0].secret_string)["token"], "")

  # Dashboards as code, organised into Grafana folders. Each subdirectory of
  # src/helm/dashboards/ maps to one Grafana folder: the map key is the on-disk
  # directory name and the value is the folder's display name. Drop a dashboard
  # JSON into the relevant subdirectory and it is provisioned into that folder
  # automatically; add a folder by adding an entry here and creating the matching
  # subdirectory.
  grafana_dashboard_root = "${path.module}/src/helm/dashboards"
  grafana_dashboard_folders = {
    platform   = "Platform"
    kubernetes = "Kubernetes"
    networking = "Networking"
    databases  = "Databases"
  }

  # Discover every dashboard JSON across the folder subdirectories, flattened into
  # a single map for the grafana_dashboard resource (grafana-dashboards.tf). The
  # key "<folder>/<name>" is stable per file; the value carries the folder it
  # belongs to and the file's path.
  grafana_dashboard_files = merge([
    for key in keys(local.grafana_dashboard_folders) : {
      for filename in fileset("${local.grafana_dashboard_root}/${key}", "*.json") :
      "${key}/${trimsuffix(filename, ".json")}" => {
        folder_key = key
        path       = "${local.grafana_dashboard_root}/${key}/${filename}"
      }
    }
  ]...)

  # The grafana provider can only manage dashboards once Grafana is deployed and a
  # real service-account token has been populated in Secrets Manager. Until then
  # (placeholder token, or the monitoring stack disabled) create no grafana
  # resources, so terraform plan/apply never tries to reach an unconfigured
  # Grafana during bootstrap.
  grafana_dashboards_manageable = local.environment_configuration.monitoring_stack_enabled && !contains(["", "CHANGEME"], local.grafana_api_token)
}

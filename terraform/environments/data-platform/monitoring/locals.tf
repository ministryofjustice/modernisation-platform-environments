locals {
  # Microsoft Entra ID (Azure AD) OAuth credentials for Grafana. The secret is
  # provisioned with placeholder values in secrets.tf and populated out-of-band,
  # then read back via the data source in data.tf. try() keeps this resolvable in
  # environments where the monitoring stack is disabled and the data source
  # therefore has no instances.
  grafana_entra_id = try(jsondecode(data.aws_secretsmanager_secret_version.grafana_entra_id[0].secret_string), {})

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

  # One provisioning provider per folder, each reading the dashboards the chart
  # mounts at /var/lib/grafana/dashboards/<key>.
  grafana_dashboard_providers = [
    for key, display_name in local.grafana_dashboard_folders : {
      name            = key
      orgId           = 1
      folder          = display_name
      type            = "file"
      disableDeletion = false
      editable        = true
      options         = { path = "/var/lib/grafana/dashboards/${key}" }
    }
  ]

  # Discover the dashboard JSON files in each folder's subdirectory, keyed by
  # filename without the .json suffix, for the chart's `dashboards` value.
  grafana_dashboards = {
    for key in keys(local.grafana_dashboard_folders) : key => {
      for filename in fileset("${local.grafana_dashboard_root}/${key}", "*.json") :
      trimsuffix(filename, ".json") => {
        json = file("${local.grafana_dashboard_root}/${key}/${filename}")
      }
    }
  }
}

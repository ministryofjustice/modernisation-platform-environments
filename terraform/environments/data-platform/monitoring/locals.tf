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

  # PagerDuty Events API v2 routing key used by the grafana_contact_point resource
  # (alerting.tf). Provisioned as a placeholder in secrets.tf and populated out-of-band;
  # try() keeps it resolvable where the monitoring stack is disabled.
  pagerduty_routing_key = try(jsondecode(data.aws_secretsmanager_secret_version.pagerduty_routing_key[0].secret_string)["routing_key"], "")

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
  # real service-account token has been populated in Secrets Manager. That state
  # cannot be detected at plan time (the token is read from a data source and is
  # unknown until apply, which would make the resources' for_each keys unknown),
  # so it is gated by the static per-environment grafana_dashboards_enabled flag:
  # flip it on once the token is in place. Until then no grafana resources exist,
  # so terraform never reaches an unconfigured Grafana.
  grafana_dashboards_manageable = local.environment_configuration.monitoring_stack_enabled && try(local.environment_configuration.grafana_dashboards_enabled, false)

  # Managing grafana_rule_group via the grafana provider
  grafana_alerting_manageable = local.grafana_dashboards_manageable

  # Convert an evaluation-interval duration string ("1m", "30s", "2h") into seconds
  interval_seconds_by_env = {
    for env, cfg in local.grafana_monitored_accounts_by_uid :
    env => (
      can(regex("^[0-9]+h$", try(cfg.evaluation_interval, local.evaluation_interval)))
      ? tonumber(trimsuffix(try(cfg.evaluation_interval, local.evaluation_interval), "h")) * 3600
      : can(regex("^[0-9]+m$", try(cfg.evaluation_interval, local.evaluation_interval)))
      ? tonumber(trimsuffix(try(cfg.evaluation_interval, local.evaluation_interval), "m")) * 60
      : tonumber(trimsuffix(try(cfg.evaluation_interval, local.evaluation_interval), "s"))
    )
  }

  # Every distinct alert-rule folder path referenced by group_folders
  # (alerting-golden-signals.tf), used to create one grafana_folder per path
  # for grafana_rule_group.folder_uid to reference.
  alert_rule_folder_paths = toset([for g in local.group_folders : g.folder])

  # Default evaluation interval for alert rules (e.g. '1m', '5m')
  evaluation_interval = "1m"

  grafana_monitored_accounts_by_name = {
    for account in try(local.environment_configuration.grafana_monitored_accounts, []) :
    account.name => account
  }

  grafana_monitored_accounts_by_uid = {
    for entry in try(local.environment_configuration.alerts_configured_accounts, []) :
    trimprefix(entry.name, "data-platform-") => merge(
      local.grafana_monitored_accounts_by_name[entry.name],
      entry,
      { uid = trimprefix(entry.name, "data-platform-") }
    )
  }

}

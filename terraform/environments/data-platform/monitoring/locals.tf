locals {

  # Grafana Entra ID OAuth credentials from Secrets Manager.
  # try() keeps this resolvable when monitoring is disabled.
  grafana_entra_id = try(jsondecode(data.aws_secretsmanager_secret_version.grafana_entra_id[0].secret_string), {})

  # Grafana API token for provider-managed dashboards/folders.
  # try() keeps this resolvable when monitoring is disabled.
  grafana_api_token = try(jsondecode(data.aws_secretsmanager_secret_version.grafana_api_token[0].secret_string)["token"], "")

  pagerduty_routing_key = try(data.aws_secretsmanager_secret_version.pagerduty_orchestrator_integration_key_secret[0].secret_string, null)
  # Dashboards as code: each src/helm/dashboards subdirectory maps to one Grafana folder.
  grafana_dashboard_root = "${path.module}/src/helm/dashboards"
  grafana_dashboard_folders = {
    platform   = "Platform"
    kubernetes = "Kubernetes"
    networking = "Networking"
    databases  = "Databases"
  }

  # Flatten dashboard JSON files into a stable map keyed as "<folder>/<name>".
  grafana_dashboard_files = merge([
    for key in keys(local.grafana_dashboard_folders) : {
      for filename in fileset("${local.grafana_dashboard_root}/${key}", "*.json") :
      "${key}/${trimsuffix(filename, ".json")}" => {
        folder_key = key
        path       = "${local.grafana_dashboard_root}/${key}/${filename}"
      }
    }
  ]...)

  # Gate Grafana provider resources behind a static flag to avoid unknown
  # for_each keys before Grafana deployment/token readiness.
  grafana_dashboards_manageable = local.environment_configuration.monitoring_stack_enabled && try(local.environment_configuration.grafana_dashboards_enabled, false)

  # Alerting resources use the same manageability gate.
  grafana_alerting_manageable = local.grafana_dashboards_manageable

  # Convert evaluation intervals (e.g. "1m", "30s", "2h") to seconds.
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

  # Distinct alert-rule folder paths for grafana_folder creation.
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

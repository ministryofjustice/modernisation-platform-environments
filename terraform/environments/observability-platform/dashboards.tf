########################################
# dashboards.tf
# - Folders are owned by module.tenant_configuration
# - This file only:
#     - discovers dashboard files under ./dashboards
#     - assigns them to the right folder
#     - renders templates
# - Works in both development & production (local.environment)
########################################

locals {
  # All plain JSON dashboard files, recursively under dashboards/
  dashboard_json_files = fileset("${path.module}/dashboards", "**/*.json")

  # All templated dashboard files (ending in .json.tftpl)
  dashboard_template_files = fileset("${path.module}/dashboards", "**/*.json.tftpl")

  # Map JSON file -> team (or null if top-level)
  # e.g. "observability-platform/demo.json" -> team = "observability-platform"
  #      "op-landing-page.json"             -> team = null
  dashboard_json_by_file = {
    for f in local.dashboard_json_files :
    f => {
      team = length(split("/", f)) > 1 ? split("/", f)[0] : null
    }
  }

  # Map template file -> team (or null if top-level)
  dashboard_template_by_file = {
    for f in local.dashboard_template_files :
    f => {
      team = length(split("/", f)) > 1 ? split("/", f)[0] : null
    }
  }
}

########################################
# Dashboards from plain JSON files
########################################

resource "grafana_dashboard" "json" {
  for_each = local.dashboard_json_by_file

  # Read the JSON file from the repo
  config_json = file("${path.module}/dashboards/${each.key}")

  # Folder:
  # - If file lives under "<team>/...", use that team's folder_id from module.tenant_configuration.
  # - If top-level, put it in Grafana "General" (folder = null).
  folder = each.value.team != null ? module.tenant_configuration[each.value.team].folder_id : null
}

########################################
# Dashboards from template files (.json.tftpl)
########################################

resource "grafana_dashboard" "templated" {
  for_each = local.dashboard_template_by_file

  # Same folder logic as above
  folder = each.value.team != null ? module.tenant_configuration[each.value.team].folder_id : null

  # Render the .json.tftpl into final JSON
  config_json = templatefile(
    "${path.module}/dashboards/${each.key}",
    {
      # From path: dashboards/<team>/<file>.json.tftpl (or "global" for top-level)
      team_name   = coalesce(each.value.team, "global")

      # From platform_locals.tf (derived from terraform.workspace, e.g. "development"/"production")
      environment = local.environment

      # UID: must be <= 40 chars, so we shorten team + name and add a short hash.
      # Format: tmpl-<team8>-<name12>-<hash6>  (5 + 1 + 8 + 1 + 12 + 1 + 6 = 34 chars max)
      dashboard_uid = format(
        "tmpl-%s-%s-%s",
        substr(coalesce(each.value.team, "global"), 0, 8),
        substr(element(split(".", basename(each.key)), 0), 0, 12),
        substr(md5(each.key), 0, 6)
      )
    }
  )
}

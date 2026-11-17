# Run `terraform init` then `terraform test` in the module directory.

mock_provider "grafana" {}

variables {
  stack_slug = "examplestack"
  metrics    = { url = "https://prometheus.example.grafana.net/api/prom", username = "100" }
  logs       = { url = "https://logs.example.grafana.net", username = "200" }
  traces     = { url = "https://tempo.example.grafana.net/tempo", username = "300" }
  read_token = "token"
  teams = {
    team-a = {
      id       = "1"
      uid      = "team-a-uid"
      accounts = { metrics = ["account-a", "account-b"], logs = ["account-a"], traces = [] }
    }
    team-b = {
      id       = "2"
      uid      = "team-b-uid"
      accounts = { metrics = ["account-b"], logs = [], traces = [] }
    }
  }
  account_ids = {
    account-a = "111111111111"
    account-b = "222222222222"
  }
}

run "label_based_access_control" {
  assert {
    condition = nonsensitive(jsondecode(grafana_data_source_config_lbac_rules.this["metrics"].rules)) == {
      team-a-uid = ["{ cloud_account_id=\"111111111111\" }", "{ cloud_account_id=\"222222222222\" }"]
      team-b-uid = ["{ cloud_account_id=\"222222222222\" }"]
    }
    error_message = "Each team should get one metrics rule per account it can query that pushes metrics."
  }

  assert {
    condition = nonsensitive(jsondecode(grafana_data_source_config_lbac_rules.this["logs"].rules)) == {
      team-a-uid = ["{ cloud_account_id=\"111111111111\" }"]
      team-b-uid = ["{ cloud_account_id=\"none\" }"]
    }
    error_message = "A team with no accounts pushing logs should get a logs rule that matches no data."
  }

  assert {
    condition = nonsensitive(jsondecode(grafana_data_source_config_lbac_rules.this["traces"].rules)) == {
      team-a-uid = ["{ resource.cloud.account.id=\"none\" }"]
      team-b-uid = ["{ resource.cloud.account.id=\"none\" }"]
    }
    error_message = "Traces rules should match the cloud.account.id resource attribute."
  }

  assert {
    condition = (
      jsonencode(sort([for p in grafana_data_source_permission.this["metrics"].permissions : p.team_id])) == jsonencode(["1", "2"]) &&
      jsonencode([for p in grafana_data_source_permission.this["logs"].permissions : p.team_id]) == jsonencode(["1"]) &&
      length(grafana_data_source_permission.this["traces"].permissions) == 0 &&
      alltrue([for p in grafana_data_source_permission.this["metrics"].permissions : p.permission == "Query"])
    )
    error_message = "Only teams with accounts pushing a signal should be able to query its data source."
  }
}

run "data_sources" {
  assert {
    condition = (
      grafana_data_source.metrics.uid == "shared-metrics" &&
      grafana_data_source.logs.uid == "shared-logs" &&
      grafana_data_source.traces.uid == "shared-traces" &&
      grafana_data_source.metrics.basic_auth_username == "100" &&
      grafana_data_source.traces.url == "https://tempo.example.grafana.net/tempo" &&
      nonsensitive(jsondecode(grafana_data_source.logs.secure_json_data_encoded).basicAuthPassword) == "token"
    )
    error_message = "The data sources should use their static UIDs and basic auth with the read token."
  }

  assert {
    condition = (
      jsondecode(grafana_data_source.metrics.json_data_encoded).exemplarTraceIdDestinations[0].datasourceUid == grafana_data_source.traces.uid &&
      jsondecode(grafana_data_source.logs.json_data_encoded).derivedFields[0].datasourceUid == grafana_data_source.traces.uid &&
      jsondecode(grafana_data_source.traces.json_data_encoded).tracesToLogsV2.datasourceUid == grafana_data_source.logs.uid &&
      jsondecode(grafana_data_source.traces.json_data_encoded).tracesToMetrics.datasourceUid == grafana_data_source.metrics.uid &&
      jsondecode(grafana_data_source.traces.json_data_encoded).serviceMap.datasourceUid == grafana_data_source.metrics.uid
    )
    error_message = "The data sources should link to each other."
  }

  assert {
    condition = (
      data.grafana_data_source.built_in["metrics"].name == "grafanacloud-examplestack-prom" &&
      data.grafana_data_source.built_in["logs"].name == "grafanacloud-examplestack-logs" &&
      data.grafana_data_source.built_in["traces"].name == "grafanacloud-examplestack-traces" &&
      alltrue([for p in grafana_data_source_permission.built_in : length(p.permissions) == 0])
    )
    error_message = "Only admins should be able to query the built-in data sources."
  }
}

run "no_teams" {
  variables {
    teams = {}
  }

  assert {
    condition = (
      alltrue([for r in grafana_data_source_config_lbac_rules.this : nonsensitive(r.rules) == "{}"]) &&
      alltrue([for p in grafana_data_source_permission.this : length(p.permissions) == 0])
    )
    error_message = "With no teams, only admins should be able to query the data sources."
  }
}

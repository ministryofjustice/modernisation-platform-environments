# Run `terraform init` then `terraform test` in the module directory.

mock_provider "grafana" {}

variables {
  name              = "account-a"
  role_arn          = "arn:aws:iam::111111111111:role/grafana-cloud"
  cloudwatch        = { enabled = true, custom_namespaces = ["ECS/ContainerInsights", "CWAgent"] }
  xray              = { enabled = false }
  amazon_prometheus = null
  query_team_ids    = ["1", "2"]
}

run "cloudwatch_only" {
  assert {
    condition = (
      length(grafana_data_source.xray) == 0 &&
      length(grafana_data_source.amazon_prometheus) == 0 &&
      jsonencode(keys(grafana_data_source_permission.this)) == jsonencode(["cloudwatch"])
    )
    error_message = "Only the CloudWatch data source and its permission should be created."
  }

  assert {
    condition = (
      jsondecode(grafana_data_source.cloudwatch[0].json_data_encoded).customMetricsNamespaces == "ECS/ContainerInsights,CWAgent" &&
      !contains(keys(jsondecode(grafana_data_source.cloudwatch[0].json_data_encoded)), "tracingDatasourceUid")
    )
    error_message = "CloudWatch should have the custom namespaces and no X-Ray link."
  }

  assert {
    condition     = length(grafana_data_source_permission.this["cloudwatch"].permissions) == 2
    error_message = "Each query team should be granted Query."
  }
}

run "all_stores" {
  variables {
    xray              = { enabled = true }
    amazon_prometheus = { workspace_id = "ws-bfdd5d7a-5571-4686-bfd4-43ab07cf8d54ba", region = "eu-west-2" }
  }

  assert {
    condition     = jsondecode(grafana_data_source.cloudwatch[0].json_data_encoded).tracingDatasourceUid == grafana_data_source.xray[0].uid
    error_message = "CloudWatch should link to the account's X-Ray data source."
  }

  assert {
    condition = (
      grafana_data_source.amazon_prometheus[0].url == "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-bfdd5d7a-5571-4686-bfd4-43ab07cf8d54ba" &&
      grafana_data_source_permission.this["amazon_prometheus"].datasource_uid == grafana_data_source.amazon_prometheus[0].uid &&
      grafana_data_source_permission.this["xray"].datasource_uid == grafana_data_source.xray[0].uid
    )
    error_message = "Each store should have a data source and a permission for it."
  }
}

run "no_query_teams" {
  variables {
    query_team_ids = []
  }

  assert {
    condition     = length(grafana_data_source_permission.this["cloudwatch"].permissions) == 0
    error_message = "With no query teams, only admins should be able to query the data sources."
  }
}

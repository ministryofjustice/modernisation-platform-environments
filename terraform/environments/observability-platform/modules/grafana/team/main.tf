resource "grafana_team" "this" {
  name = var.name
  team_sync {
    groups = [data.aws_identitystore_group.this.id]
  }
}

resource "grafana_folder" "this" {
  title = var.name
}

resource "grafana_folder_permission" "this" {
  folder_uid = grafana_folder.this.uid
  permissions {
    team_id    = grafana_team.this.id
    permission = "Admin"
  }
}

data "grafana_data_source" "cloudwatch" {
  for_each = var.aws_accounts

  name = "${each.key}-cloudwatch"
}

resource "grafana_data_source_permission" "cloudwatch" {
  for_each = var.aws_accounts

  datasource_uid = trimprefix(data.grafana_data_source.cloudwatch[each.key].id, "1:")

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}

data "grafana_data_source" "xray" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.xray_enabled
  }

  name = "${each.key}-xray"
}

resource "grafana_data_source_permission" "xray" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.xray_enabled
  }

  datasource_uid = trimprefix(data.grafana_data_source.xray[each.key].id, "1:")

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}

data "grafana_data_source" "athena" {
  for_each = {
    for name, config in var.aws_accounts : name => config if config.athena_enabled
  }

  name = "${each.key}-athena"
}

resource "grafana_data_source_permission" "athena" {
  for_each = {
    for name, config in var.aws_accounts : name => config if config.athena_enabled
  }

  datasource_uid = trimprefix(data.grafana_data_source.athena[each.key].id, "1:")

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}

data "grafana_data_source" "amazon_prometheus" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.amazon_prometheus_query_enabled
  }

  name = "${each.key}-amp"
}

resource "grafana_data_source_permission" "amazon_prometheus" {
  for_each = {
    for name, account in var.aws_accounts : name => account if account.amazon_prometheus_query_enabled
  }

  datasource_uid = trimprefix(data.grafana_data_source.amazon_prometheus[each.key].id, "1:")

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}

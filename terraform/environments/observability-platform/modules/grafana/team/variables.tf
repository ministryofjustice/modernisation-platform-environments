variable "name" {
  type = string
}

variable "identity_centre_team" {
  type = string
}

variable "aws_accounts" {
  type = map(any)
}

data "grafana_data_source" "cloudwatch" {
  for_each = var.aws_accounts

  name = "${each.key}-cloudwatch"
}

resource "grafana_data_source_permission" "cloudwatch" {
  for_each = var.aws_accounts

  datasource_id = data.grafana_data_source.cloudwatch[each.key].id

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

  datasource_id = data.grafana_data_source.xray[each.key].id

  permissions {
    team_id    = grafana_team.this.id
    permission = "Query"
  }
}

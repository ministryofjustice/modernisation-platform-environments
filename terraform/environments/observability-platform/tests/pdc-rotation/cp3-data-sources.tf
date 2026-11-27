# Exercise the real data-source module as well as the PDC resources in the handoff plan.
module "grafana_cloud_aws_data_sources" {
  source    = "./aws-account-data-sources"
  for_each  = module.checked_in_configuration.accounts
  providers = { grafana = grafana.stack }

  name              = each.key
  role_arn          = "arn:aws:iam::${local.all_account_ids[each.key]}:role/grafana-cloud"
  cloudwatch        = each.value.cloudwatch
  xray              = each.value.xray
  amazon_prometheus = each.value.amazon_prometheus
  query_team_ids    = ["1"]
}

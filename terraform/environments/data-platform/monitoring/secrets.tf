module "grafana_entra_id_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  name = "${local.component_name}/grafana-entra-id"

  secret_string = jsonencode({
    client_id     = "CHANGEME"
    client_secret = "CHANGEME"
    tenant_id     = "CHANGEME"
  })
  ignore_secret_changes = true
}
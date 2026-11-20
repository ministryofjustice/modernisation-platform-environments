mock_provider "aws" {}
mock_provider "grafana" {
  alias = "cloud"
}

run "no_pdc_accounts" {
  command = plan

  variables {
    accounts = {}
  }

  assert {
    condition = (
      length(aws_secretsmanager_secret.gc_pdc_token) == 0 &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 0 &&
      length(local.gc_pdc_rotation_tags) == 0 &&
      length(module.grafana_pdc_token_rotator) == 0
    )
    error_message = "An environment without opted-in accounts must not create PDC secrets or a rotator."
  }
}

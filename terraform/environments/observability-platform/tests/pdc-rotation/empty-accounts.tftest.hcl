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

run "production_has_no_development_ecr_parameter" {
  command = plan

  variables {
    environment = "production"
    accounts    = {}
  }

  assert {
    condition     = length(aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri) == 0
    error_message = "The rotator ECR repository URI parameter is development-only."
  }
}

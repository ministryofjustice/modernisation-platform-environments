mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}
mock_provider "grafana" {
  alias = "cloud"
}

mock_provider "grafana" {
  alias = "stack"
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
      length(aws_secretsmanager_secret_rotation.gc_pdc_token) == 0 &&
      length(local.gc_pdc_rotation_tags) == 0 &&
      length(module.grafana_pdc_token_rotator) == 0 &&
      length(aws_sns_topic.gc_pdc_failure_alerts) == 1
    )
    error_message = "An environment without opted-in accounts must not create PDC secrets or a rotator, while configured failure alerts remain available."
  }
}

run "production_opt_in_without_rotator_is_rejected" {
  command = plan

  variables {
    environment = "production"
    accounts = {
      production-observability-a = { pdc_enabled = true }
    }
  }

  expect_failures = [terraform_data.gc_pdc_bootstrap["production-observability-a"]]
}

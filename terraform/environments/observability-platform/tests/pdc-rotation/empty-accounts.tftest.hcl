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
      length(aws_secretsmanager_secret_rotation.gc_pdc_token) == 0 &&
      length(local.gc_pdc_rotation_tags) == 0 &&
      length(module.grafana_pdc_token_rotator) == 0 &&
      length(aws_sns_topic.gc_pdc_failure_alerts) == 1
    )
    error_message = "An environment without opted-in accounts must not create PDC secrets or a rotator, while configured failure alerts remain available."
  }
}

run "production_has_no_development_ecr_parameter" {
  command = plan

  variables {
    environment                   = "production"
    use_environment_configuration = true
  }

  assert {
    condition = (
      length(aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri) == 0 &&
      length(aws_secretsmanager_secret_rotation.gc_pdc_token) == 0 &&
      length(terraform_data.gc_pdc_bootstrap) == 0 &&
      length(aws_sns_topic.gc_pdc_failure_alerts) == 0 &&
      length(module.gc_pdc_failure_chatbot) == 0 &&
      length(module.grafana_pdc_token_rotator) == 0 &&
      length(aws_secretsmanager_secret.gc_pdc_rotator_credential) == 0 &&
      length(aws_kms_key.gc_pdc_rotator_credential) == 0 &&
      length(grafana_cloud_access_policy.gc_pdc_rotator) == 0 &&
      length(grafana_cloud_stack_service_account.gc_pdc_rotator_query) == 0 &&
      length(grafana_data_source_permission_item.gc_pdc_rotator_query) == 0
    )
    error_message = "The rotator ECR parameter and development-only Slack alert wiring must not be deployed in production."
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

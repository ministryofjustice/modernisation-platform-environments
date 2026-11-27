mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::@MOCK_PLATFORM_ACCOUNT@:policy/grafana-pdc-token-rotator" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::@MOCK_PLATFORM_ACCOUNT@:role/grafana-pdc-token-rotator" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "@MOCK_PLATFORM_ACCOUNT@" }
  }
  mock_data "aws_region" {
    defaults = { name = "eu-west-2" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_resource "aws_secretsmanager_secret" {
    defaults = { arn = "arn:aws:secretsmanager:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:secret:grafana-cloud/pdc/mock-ABCDEF" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:key/12345678-1234-1234-1234-abcdefabcdef" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:grafana-pdc-rotation-failures-development" }
  }
  mock_resource "aws_ssm_parameter" {}
  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:function:grafana-pdc-token-rotator"
    }
  }
}

mock_provider "grafana" {
  alias = "cloud"
}

mock_provider "grafana" {
  alias = "stack"
}

# The checked-in production configuration: the Cloud Platform and Container Platform accounts that
# use the production Grafana Cloud stack. Every one of them is bootstrapped centrally, none is seeded.
run "production_cloud_and_container_platform_accounts" {
  command = plan

  variables {
    environment                   = "production"
    use_environment_configuration = true
  }

  assert {
    condition = (
      toset(keys(local.gc_pdc_accounts)) == toset([
        "cloud-platform-preproduction", "cloud-platform-nonlive", "cloud-platform-live",
        "container-platform-octo-nonlive", "container-platform-octo-live",
        "container-platform-laa-nonlive", "container-platform-laa-live",
        "container-platform-hmpps-nonlive", "container-platform-hmpps-live",
        "container-platform-cd-nonlive", "container-platform-cd-live",
      ]) &&
      alltrue([for names in [
        keys(local.gc_pdc_bootstrap_accounts), keys(grafana_cloud_private_data_source_connect_network.account),
        keys(aws_kms_key.gc_pdc_token), keys(aws_secretsmanager_secret.gc_pdc_token),
        keys(aws_secretsmanager_secret_policy.gc_pdc_token), keys(terraform_data.gc_pdc_bootstrap),
        keys(aws_cloudwatch_event_rule.gc_pdc_enrolment), keys(aws_cloudwatch_event_target.gc_pdc_enrolment),
        keys(aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery),
      ] : toset(names) == toset(keys(local.gc_pdc_accounts))]) &&
      length(aws_lambda_permission.gc_pdc_bootstrap) == 1 &&
      length(aws_lambda_permission.gc_pdc_enrolment_tick) == 1 &&
      length(aws_lambda_permission.gc_pdc_enrolment_rotation) == 1
    )
    error_message = "Every production Cloud Platform and Container Platform account must get a PDC network, protected secret, first-issuance marker and readiness tick."
  }

  assert {
    condition = (
      length(local.gc_pdc_seeded_accounts) == 0 &&
      length(aws_secretsmanager_secret_rotation.gc_pdc_token) == 0 &&
      length(aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri) == 0
    )
    error_message = "Production has no seeded accounts, no Terraform-managed rotation schedules and no development-only ECR parameter."
  }

  assert {
    condition = (
      aws_secretsmanager_secret.gc_pdc_token["cloud-platform-live"].tags["pdc:bootstrap"] == "true" &&
      aws_secretsmanager_secret.gc_pdc_token["cloud-platform-live"].tags["pdc:rotation-interval-days"] == "90" &&
      aws_secretsmanager_secret.gc_pdc_token["cloud-platform-live"].tags["pdc:token-ttl-seconds"] == tostring(97 * 86400) &&
      aws_secretsmanager_secret.gc_pdc_token["cloud-platform-live"].tags["pdc:tenant-account-id"] == format("%012d", 22) &&
      local.gc_pdc_network_names["container-platform-hmpps-live"] == "mojobservabilityproduction-container-platform-hmpps-live" &&
      local.gc_pdc_agent_principal_arns["container-platform-cd-nonlive"] == "arn:aws:iam::${format("%012d", 29)}:role/grafana-pdc-agent-execution" &&
      local.gc_pdc_restarter_role_arns["container-platform-laa-live"] == "arn:aws:iam::${format("%012d", 26)}:role/grafana-pdc-agent-restarter"
    )
    error_message = "Production secrets must be tagged for first issuance, named for the production stack and trust only the tenant agent roles."
  }

  assert {
    condition = (
      length(aws_sns_topic.gc_pdc_failure_alerts) == 1 &&
      length(module.gc_pdc_failure_chatbot) == 1 &&
      length(module.grafana_pdc_token_rotator) == 1 &&
      length(aws_secretsmanager_secret.gc_pdc_rotator_credential) == 2 &&
      length(aws_kms_key.gc_pdc_rotator_credential) == 2 &&
      length(grafana_cloud_access_policy.gc_pdc_rotator) == 1 &&
      length(grafana_cloud_stack_service_account.gc_pdc_rotator_query) == 1 &&
      length(grafana_data_source_permission_item.gc_pdc_rotator_query) == 1
    )
    error_message = "Production deploys the common rotator runtime, credential secrets and alerts."
  }

  assert {
    condition = (
      module.checked_in_configuration.failure_alerts.slack_channel_id == "C06RA6C52TW" &&
      module.checked_in_configuration.rotator.bootstrap_enabled &&
      can(regex("^sha256:[0-9a-f]{64}$", module.checked_in_configuration.rotator.image_digest))
    )
    error_message = "Production must use its own Slack alert channel and a pinned bootstrap-capable rotator."
  }
}

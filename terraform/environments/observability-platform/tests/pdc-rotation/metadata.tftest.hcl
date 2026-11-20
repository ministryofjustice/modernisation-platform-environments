mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "444444444444" }
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
    defaults = { arn = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:grafana-cloud/pdc/mock-ABCDEF" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:eu-west-2:444444444444:key/12345678-1234-1234-1234-123456789012" }
  }
}

mock_provider "grafana" {
  alias = "cloud"
}

override_resource {
  target = grafana_cloud_stack.observability_platform
  values = { id = "12345" }
}

override_resource {
  target = grafana_cloud_private_data_source_connect_network.account["sprinkler-development"]
  values = { pdc_network_id = "sprinkler-network" }
}

override_resource {
  target = grafana_cloud_private_data_source_connect_network.account["cooker-development"]
  values = { pdc_network_id = "cooker-network" }
}

run "central_metadata_without_activation" {
  command = apply

  assert {
    condition = (
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].name == "grafana-cloud/pdc/111111111111" &&
      aws_secretsmanager_secret.gc_pdc_token["cooker-development"].name == "grafana-cloud/pdc/222222222222" &&
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].tags["pdc:access-policy-id"] == "sprinkler-network" &&
      aws_secretsmanager_secret.gc_pdc_token["cooker-development"].tags["pdc:access-policy-id"] == "cooker-network" &&
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].tags["pdc:tenant-account-id"] == "111111111111" &&
      aws_secretsmanager_secret.gc_pdc_token["cooker-development"].tags["pdc:tenant-account-id"] == "222222222222"
    )
    error_message = "Keep the existing per-account secret names and map metadata to each account's own network."
  }

  assert {
    condition = alltrue([
      for secret in aws_secretsmanager_secret.gc_pdc_token : (
        secret.tags["pdc:stack-id"] == "12345" &&
        secret.tags["pdc:region"] == "prod-gb-south-1" &&
        secret.tags["pdc:ecs-region"] == "eu-west-2" &&
        secret.tags["pdc:ecs-cluster"] == "grafana-pdc-agent" &&
        secret.tags["pdc:ecs-service"] == "grafana-pdc-agent" &&
        tonumber(secret.tags["pdc:token-ttl-seconds"]) == local.pdc_rotation_rules.automatically_after_days * 86400 + local.pdc_token_grace_days * 86400
      )
    ])
    error_message = "Runtime expiry must derive from the same interval as the schedule plus grace, with distinct Grafana and ECS regions."
  }

  assert {
    condition = (
      !contains(keys(aws_secretsmanager_secret.gc_pdc_token), "disabled-development") &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 2 &&
      length(aws_secretsmanager_secret_version.gc_pdc_token) == 2 &&
      length(module.grafana_pdc_token_rotator) == 0 &&
      length(aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors) == 0 &&
      length(aws_cloudwatch_event_target.gc_pdc_rotation_failed) == 0
    )
    error_message = "Preserve bootstrap tokens and opt-in behaviour; do not deploy the rotator or alerts without a configured image."
  }
}

run "prepared_runtime_permissions" {
  command = plan

  variables {
    rotator = {
      image_uri              = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn      = "arn:aws:sns:eu-west-2:444444444444:test-pdc-failures"
    }
  }

  assert {
    condition = (
      toset(jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement[4].Resource) == toset([
        "arn:aws:iam::111111111111:role/grafana-pdc-agent-restarter",
        "arn:aws:iam::222222222222:role/grafana-pdc-agent-restarter",
      ]) &&
      jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement[1].Resource == [var.rotator.credential_secret_arn] &&
      jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement[3].Resource == [var.rotator.credential_kms_key_arn]
    )
    error_message = "Allow only opted-in tenant restarter roles and the dedicated credential secret/key."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors["this"].alarm_actions == toset([var.rotator.failure_topic_arn]) &&
      aws_cloudwatch_event_target.gc_pdc_rotation_failed["this"].arn == var.rotator.failure_topic_arn &&
      jsondecode(aws_cloudwatch_event_rule.gc_pdc_rotation_failed["this"].event_pattern).detail.eventName == ["RotationFailed"]
    )
    error_message = "Alert on both Lambda errors and Secrets Manager rotation failures."
  }
}

run "reject_cross_account_credential" {
  command = plan

  variables {
    rotator = {
      image_uri              = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:999999999999:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn      = "arn:aws:sns:eu-west-2:444444444444:test-pdc-failures"
    }
  }

  expect_failures = [aws_iam_policy.gc_pdc_rotator["this"]]
}

run "reject_wrong_region_failure_destination" {
  command = plan

  variables {
    rotator = {
      image_uri              = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn      = "arn:aws:sns:eu-west-1:444444444444:test-pdc-failures"
    }
  }

  expect_failures = [aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors["this"]]
}

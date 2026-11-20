mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::444444444444:policy/grafana-pdc-token-rotator" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::444444444444:role/grafana-pdc-token-rotator" }
  }
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
  values = {
    id  = "12345"
    url = "https://example.grafana.net"
  }
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
      !contains(keys(aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].tags), "pdc:metrics-tunnel-id") &&
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
      length(aws_dynamodb_table.gc_pdc_rotation_state) == 0 &&
      length(aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors) == 0 &&
      length(aws_cloudwatch_event_target.gc_pdc_rotation_failed) == 0
    )
    error_message = "Preserve bootstrap tokens and opt-in behaviour; do not deploy the rotator or alerts without a configured image."
  }
}

run "prepared_runtime_permissions" {
  state_key = "prepared_runtime"
  command   = apply

  variables {
    rotator = {
      image_uri                          = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn              = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn             = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn                  = "arn:aws:sns:eu-west-2:444444444444:test-pdc-failures"
      stack_query_credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-stack-query-ABCDEF"
      stack_query_credential_kms_key_arn = "arn:aws:kms:eu-west-2:444444444444:key/12345678-4321-4321-4321-210987654321"
      metrics_tunnel_ids = {
        sprinkler-development = "observed-sprinkler-tunnel"
        cooker-development    = "observed-cooker-tunnel"
      }
    }
  }

  assert {
    condition = (
      toset(one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if s.Sid == "AssumeTenantRestarters"])) == toset([
        "arn:aws:iam::111111111111:role/grafana-pdc-agent-restarter",
        "arn:aws:iam::222222222222:role/grafana-pdc-agent-restarter",
      ]) &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if s.Sid == "ReadGrafanaCredential"]) == [var.rotator.credential_secret_arn] &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if s.Sid == "ReadStackQueryCredential"]) == {
        Sid      = "ReadStackQueryCredential"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.rotator.stack_query_credential_secret_arn]
      } &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if s.Sid == "DecryptStackQueryCredential"]) == {
        Sid      = "DecryptStackQueryCredential"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [var.rotator.stack_query_credential_kms_key_arn]
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.eu-west-2.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = var.rotator.stack_query_credential_secret_arn
          }
        }
      }
    )
    error_message = "Allow only opted-in tenant restarter roles and the dedicated credential secret/key."
  }

  assert {
    condition = (
      local.gc_pdc_rotator_environment.this.GRAFANA_STACK_URL == grafana_cloud_stack.observability_platform.url &&
      local.gc_pdc_rotator_environment.this.GRAFANA_USAGE_DATASOURCE_UID == "grafanacloud-usage" &&
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].tags["pdc:metrics-tunnel-id"] == "observed-sprinkler-tunnel" &&
      local.gc_pdc_rotator_environment.this.GRAFANA_STACK_QUERY_CREDENTIAL_SECRET_ARN == var.rotator.stack_query_credential_secret_arn &&
      local.gc_pdc_rotator_environment.this.GRAFANA_API_CREDENTIAL_SECRET_ARN == var.rotator.credential_secret_arn
    )
    error_message = "Use the managed stack URL and the separate query and management secret references."
  }

  assert {
    condition = (
      aws_dynamodb_table.gc_pdc_rotation_state["this"].hash_key == "rotation_id" &&
      local.gc_pdc_rotator_environment.this.ROTATION_STATE_TABLE_NAME == aws_dynamodb_table.gc_pdc_rotation_state["this"].name &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if s.Sid == "ManageRotationJournal"]) == {
        Sid      = "ManageRotationJournal"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = [aws_dynamodb_table.gc_pdc_rotation_state["this"].arn]
      }
    )
    error_message = "Use the agreed journal key and grant only item reads and writes to that table."
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
      image_uri                          = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn              = "arn:aws:secretsmanager:eu-west-2:999999999999:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn             = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn                  = "arn:aws:sns:eu-west-2:444444444444:test-pdc-failures"
      stack_query_credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-stack-query-ABCDEF"
      stack_query_credential_kms_key_arn = "arn:aws:kms:eu-west-2:444444444444:key/12345678-4321-4321-4321-210987654321"
      metrics_tunnel_ids = {
        sprinkler-development = "observed-sprinkler-tunnel"
        cooker-development    = "observed-cooker-tunnel"
      }
    }
  }

  expect_failures = [aws_iam_policy.gc_pdc_rotator["this"]]
}

run "reject_wrong_region_failure_destination" {
  command = plan

  variables {
    rotator = {
      image_uri                          = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn              = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn             = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn                  = "arn:aws:sns:eu-west-1:444444444444:test-pdc-failures"
      stack_query_credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-stack-query-ABCDEF"
      stack_query_credential_kms_key_arn = "arn:aws:kms:eu-west-2:444444444444:key/12345678-4321-4321-4321-210987654321"
      metrics_tunnel_ids = {
        sprinkler-development = "observed-sprinkler-tunnel"
        cooker-development    = "observed-cooker-tunnel"
      }
    }
  }

  expect_failures = [aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors["this"]]
}

run "reject_out_of_region_stack_query_key" {
  command = plan

  variables {
    rotator = {
      image_uri                          = "444444444444.dkr.ecr.eu-west-2.amazonaws.com/test-pdc-rotator@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      credential_secret_arn              = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-credential-ABCDEF"
      credential_kms_key_arn             = "arn:aws:kms:eu-west-2:444444444444:key/87654321-4321-4321-4321-210987654321"
      failure_topic_arn                  = "arn:aws:sns:eu-west-2:444444444444:test-pdc-failures"
      stack_query_credential_secret_arn  = "arn:aws:secretsmanager:eu-west-2:444444444444:secret:test-pdc-stack-query-ABCDEF"
      stack_query_credential_kms_key_arn = "arn:aws:kms:eu-west-1:444444444444:key/12345678-4321-4321-4321-210987654321"
      metrics_tunnel_ids = {
        sprinkler-development = "observed-sprinkler-tunnel"
        cooker-development    = "observed-cooker-tunnel"
      }
    }
  }

  expect_failures = [aws_iam_policy.gc_pdc_rotator["this"]]
}

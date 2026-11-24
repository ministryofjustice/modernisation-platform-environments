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
}

mock_provider "grafana" {
  alias = "cloud"
}

mock_provider "grafana" {
  alias = "stack"
}

override_resource {
  target = grafana_cloud_stack_service_account.gc_pdc_rotator_query["this"]
  values = { id = "mojobservabilitydevelopment:678" }
}

override_resource {
  target = aws_secretsmanager_secret.gc_pdc_rotator_credential["management-token"]
  values = { arn = "arn:aws:secretsmanager:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:secret:grafana-cloud/pdc-token-rotator/management-token-ABCDEF" }
}

override_resource {
  target = aws_secretsmanager_secret.gc_pdc_rotator_credential["stack-query-token"]
  values = { arn = "arn:aws:secretsmanager:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:secret:grafana-cloud/pdc-token-rotator/stack-query-token-ABCDEF" }
}

override_resource {
  target = aws_kms_key.gc_pdc_rotator_credential["management-token"]
  values = { arn = "arn:aws:kms:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:key/87654321-4321-4321-4321-fedcbafedcba" }
}

override_resource {
  target = aws_kms_key.gc_pdc_rotator_credential["stack-query-token"]
  values = { arn = "arn:aws:kms:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:key/12345678-4321-4321-4321-fedcbafedcba" }
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
      aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri[0].name == "/observability-platform/grafana-pdc-token-rotator/ecr-repository-uri" &&
      aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri[0].type == "String" &&
      nonsensitive(aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri[0].value) == format(
        "%s.dkr.ecr.eu-west-2.amazonaws.com/observability-platform-grafana-pdc-token-rotator",
        local.environment_management.account_ids["core-shared-services-production"]
      ) &&
      aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri[0].tags.application == local.tags.application &&
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].name == "grafana-cloud/pdc/${format("%012d", 1)}" &&
      aws_secretsmanager_secret.gc_pdc_token["cooker-development"].name == "grafana-cloud/pdc/${format("%012d", 2)}" &&
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].tags["pdc:access-policy-id"] == "sprinkler-network" &&
      aws_secretsmanager_secret.gc_pdc_token["cooker-development"].tags["pdc:access-policy-id"] == "cooker-network" &&
      aws_secretsmanager_secret.gc_pdc_token["sprinkler-development"].tags["pdc:tenant-account-id"] == format("%012d", 1) &&
      aws_secretsmanager_secret.gc_pdc_token["cooker-development"].tags["pdc:tenant-account-id"] == format("%012d", 2)
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
      length(aws_cloudwatch_event_target.gc_pdc_rotation_failed) == 0 &&
      length(aws_secretsmanager_secret.gc_pdc_rotator_credential) == 0 &&
      length(aws_kms_key.gc_pdc_rotator_credential) == 0 &&
      length(grafana_cloud_access_policy.gc_pdc_rotator) == 0 &&
      length(grafana_cloud_stack_service_account.gc_pdc_rotator_query) == 0 &&
      length(grafana_data_source_permission_item.gc_pdc_rotator_query) == 0 &&
      length(aws_sns_topic.gc_pdc_failure_alerts) == 1 &&
      length(module.gc_pdc_failure_chatbot) == 1
    )
    error_message = "Keep the rotator dormant while deploying the configured development alert destination independently."
  }

  assert {
    condition = (
      local.gc_pdc_failure_alerts.this.slack_channel_id == "C06ALD6LX55" &&
      aws_sns_topic.gc_pdc_failure_alerts["this"].name == "grafana-pdc-rotation-failures-development" &&
      aws_sns_topic.gc_pdc_failure_alerts["this"].kms_master_key_id == aws_kms_key.gc_pdc_failure_alerts["this"].arn &&
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[0].Condition.StringEquals["aws:SourceAccount"] == data.aws_caller_identity.current.account_id &&
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"] == local.gc_pdc_failure_alarm_arn &&
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[1].Condition.StringEquals["aws:SourceAccount"] == data.aws_caller_identity.current.account_id &&
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[1].Condition.ArnEquals["aws:SourceArn"] == local.gc_pdc_failure_rule_arn &&
      one([for statement in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : statement if statement.Sid == "AllowCloudWatchAlarmToUseKey"]).Condition.StringEquals["aws:SourceAccount"] == data.aws_caller_identity.current.account_id &&
      one([for statement in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : statement if statement.Sid == "AllowCloudWatchAlarmToUseKey"]).Condition.ArnEquals["aws:SourceArn"] == local.gc_pdc_failure_alarm_arn &&
      one([for statement in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : statement if statement.Sid == "AllowEventBridgeRuleToUseKey"]).Condition.StringEquals["aws:SourceAccount"] == data.aws_caller_identity.current.account_id &&
      one([for statement in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : statement if statement.Sid == "AllowEventBridgeRuleToUseKey"]).Condition.ArnEquals["aws:SourceArn"] == local.gc_pdc_failure_rule_arn
    )
    error_message = "Configure encrypted Slack delivery with CloudWatch and EventBridge access scoped to their source ARNs."
  }
}

run "prepared_runtime_permissions" {
  state_key = "prepared_runtime"
  command   = apply

  variables {
    rotator = {
      image_digest = "sha256:4c6c3ae52a2bb17e8e0e4703d533f4253c2df9fa6b9dffd1deabf6e4262208b3"
    }
  }

  assert {
    condition = (
      toset(one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if s.Sid == "AssumeTenantRestarters"])) == toset([
        "arn:aws:iam::${format("%012d", 1)}:role/grafana-pdc-agent-restarter",
        "arn:aws:iam::${format("%012d", 2)}:role/grafana-pdc-agent-restarter",
      ]) &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if s.Sid == "ReadGrafanaCredential"]) == [aws_secretsmanager_secret.gc_pdc_rotator_credential["management-token"].arn] &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if s.Sid == "DecryptGrafanaCredential"]) == {
        Sid      = "DecryptGrafanaCredential"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [aws_kms_key.gc_pdc_rotator_credential["management-token"].arn]
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.eu-west-2.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = aws_secretsmanager_secret.gc_pdc_rotator_credential["management-token"].arn
          }
        }
      } &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if s.Sid == "ReadStackQueryCredential"]) == {
        Sid      = "ReadStackQueryCredential"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.gc_pdc_rotator_credential["stack-query-token"].arn]
      } &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if s.Sid == "DecryptStackQueryCredential"]) == {
        Sid      = "DecryptStackQueryCredential"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [aws_kms_key.gc_pdc_rotator_credential["stack-query-token"].arn]
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.eu-west-2.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = aws_secretsmanager_secret.gc_pdc_rotator_credential["stack-query-token"].arn
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
      local.gc_pdc_rotator_environment.this.GRAFANA_STACK_QUERY_CREDENTIAL_SECRET_ARN == aws_secretsmanager_secret.gc_pdc_rotator_credential["stack-query-token"].arn &&
      local.gc_pdc_rotator_environment.this.GRAFANA_API_CREDENTIAL_SECRET_ARN == aws_secretsmanager_secret.gc_pdc_rotator_credential["management-token"].arn
    )
    error_message = "Use the managed stack URL and the separate query and management secret references."
  }

  assert {
    condition = (
      length(aws_secretsmanager_secret.gc_pdc_rotator_credential) == 2 &&
      length(aws_kms_key.gc_pdc_rotator_credential) == 2 &&
      aws_secretsmanager_secret.gc_pdc_rotator_credential["management-token"].arn != aws_secretsmanager_secret.gc_pdc_rotator_credential["stack-query-token"].arn &&
      aws_kms_key.gc_pdc_rotator_credential["management-token"].arn != aws_kms_key.gc_pdc_rotator_credential["stack-query-token"].arn &&
      alltrue([
        for name, secret in aws_secretsmanager_secret.gc_pdc_rotator_credential : (
          secret.name == "grafana-cloud/pdc-token-rotator/${name}" &&
          secret.kms_key_id == aws_kms_key.gc_pdc_rotator_credential[name].arn &&
          aws_kms_alias.gc_pdc_rotator_credential[name].name == "alias/grafana-cloud-pdc-token-rotator-${name}" &&
          aws_kms_alias.gc_pdc_rotator_credential[name].target_key_id == aws_kms_key.gc_pdc_rotator_credential[name].key_id &&
          aws_kms_key.gc_pdc_rotator_credential[name].enable_key_rotation &&
          one([for s in jsondecode(aws_kms_key.gc_pdc_rotator_credential[name].policy).Statement : s if s.Sid == "AllowRotatorToDecryptCredential"]).Action == ["kms:Decrypt"] &&
          one([for s in jsondecode(aws_kms_key.gc_pdc_rotator_credential[name].policy).Statement : s if s.Sid == "AllowRotatorToDecryptCredential"]).Condition.ArnEquals["aws:PrincipalArn"] == "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/grafana-pdc-token-rotator" &&
          one([for s in jsondecode(aws_kms_key.gc_pdc_rotator_credential[name].policy).Statement : s if s.Sid == "AllowRotatorToDecryptCredential"]).Condition.StringEquals["kms:ViaService"] == "secretsmanager.eu-west-2.amazonaws.com" &&
          one([for s in jsondecode(aws_kms_key.gc_pdc_rotator_credential[name].policy).Statement : s if s.Sid == "AllowRotatorToDecryptCredential"]).Condition.ArnLike["kms:EncryptionContext:SecretARN"] == "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${secret.name}-??????"
        )
      ]) &&
      length(aws_secretsmanager_secret_version.gc_pdc_token) == 2 &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 2
    )
    error_message = "Create distinct credential secrets and keys outside the tenant namespace, with decryption restricted to the rotator and each secret."
  }

  assert {
    condition = (
      grafana_cloud_access_policy.gc_pdc_rotator["this"].name == "pdc-token-rotator-development" &&
      grafana_cloud_access_policy.gc_pdc_rotator["this"].region == grafana_cloud_stack.observability_platform.region_slug &&
      grafana_cloud_access_policy.gc_pdc_rotator["this"].scopes == toset(["accesspolicies:read", "accesspolicies:write"]) &&
      one(grafana_cloud_access_policy.gc_pdc_rotator["this"].realm).type == "stack" &&
      one(grafana_cloud_access_policy.gc_pdc_rotator["this"].realm).identifier == grafana_cloud_stack.observability_platform.id &&
      grafana_cloud_stack_service_account.gc_pdc_rotator_query["this"].role == "None" &&
      grafana_cloud_stack_service_account.gc_pdc_rotator_query["this"].stack_slug == grafana_cloud_stack.observability_platform.slug &&
      grafana_data_source_permission_item.gc_pdc_rotator_query["this"].datasource_uid == "grafanacloud-usage" &&
      grafana_data_source_permission_item.gc_pdc_rotator_query["this"].permission == "Query" &&
      grafana_data_source_permission_item.gc_pdc_rotator_query["this"].user == "678" &&
      grafana_data_source_permission_item.gc_pdc_rotator_query["this"].role == null &&
      grafana_data_source_permission_item.gc_pdc_rotator_query["this"].team == null
    )
    error_message = "Grant only stack-scoped policy management and a single usage-query permission to the role-None service account."
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
      aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors["this"].alarm_actions == toset([aws_sns_topic.gc_pdc_failure_alerts["this"].arn]) &&
      aws_cloudwatch_event_target.gc_pdc_rotation_failed["this"].arn == aws_sns_topic.gc_pdc_failure_alerts["this"].arn &&
      jsondecode(aws_cloudwatch_event_rule.gc_pdc_rotation_failed["this"].event_pattern).detail.eventName == ["RotationFailed"]
    )
    error_message = "Alert on both Lambda errors and Secrets Manager rotation failures."
  }
}

run "reject_unpinned_image" {
  command = plan

  variables {
    rotator = {
      image_digest = "v0.1.0-alpha.1"
    }
  }

  expect_failures = [aws_iam_policy.gc_pdc_rotator["this"]]
}

run "reject_missing_failure_destination" {
  command = plan

  variables {
    rotator = {
      image_digest = "sha256:4c6c3ae52a2bb17e8e0e4703d533f4253c2df9fa6b9dffd1deabf6e4262208b3"
    }
    failure_alerts = null
  }

  expect_failures = [aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors["this"], aws_cloudwatch_event_target.gc_pdc_rotation_failed["this"]]
}

run "reject_rotator_without_pdc_accounts" {
  state_key = "empty_rotator"
  command   = plan

  variables {
    accounts = {}
    rotator = {
      image_digest = "sha256:4c6c3ae52a2bb17e8e0e4703d533f4253c2df9fa6b9dffd1deabf6e4262208b3"
    }
  }

  expect_failures = [aws_iam_policy.gc_pdc_rotator["this"]]
}

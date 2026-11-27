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
  mock_resource "aws_cloudwatch_event_rule" {
    defaults = { arn = "arn:aws:events:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:rule/mock" }
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

override_resource {
  target = grafana_cloud_stack_service_account.gc_pdc_rotator_query["this"]
  values = { id = "mojobservabilitydevelopment:678" }
}

override_resource {
  target = aws_secretsmanager_secret.gc_pdc_rotator_credential["management-token"]
  values = { arn = "arn:aws:secretsmanager:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:secret:grafana-cloud/pdc-token-rotator/management-token-ABCDEF" }
}

override_resource {
  target = aws_secretsmanager_secret.gc_pdc_token["new-development"]
  values = { arn = "arn:aws:secretsmanager:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:secret:grafana-cloud/pdc/@MOCK_NEW_ACCOUNT@-ABCDEF" }
}

override_resource {
  target = aws_cloudwatch_event_rule.gc_pdc_enrolment["new-development"]
  values = { arn = "arn:aws:events:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:rule/pdc-enrol-new-development" }
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
      length(terraform_data.gc_pdc_bootstrap) == 0 &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 0 &&
      length(aws_secretsmanager_secret_version.gc_pdc_token) == 0 &&
      length(aws_secretsmanager_secret_rotation.gc_pdc_token) == 0 &&
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
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"] == [local.gc_pdc_failure_alarm_arn] &&
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[1].Condition.StringEquals["aws:SourceAccount"] == data.aws_caller_identity.current.account_id &&
      jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[1].Condition.ArnEquals["aws:SourceArn"] == local.gc_pdc_failure_rule_arn &&
      one([for statement in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : statement if statement.Sid == "AllowCloudWatchAlarmToUseKey"]).Condition.StringEquals["aws:SourceAccount"] == data.aws_caller_identity.current.account_id &&
      one([for statement in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : statement if statement.Sid == "AllowCloudWatchAlarmToUseKey"]).Condition.ArnEquals["aws:SourceArn"] == [local.gc_pdc_failure_alarm_arn] &&
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
      image_digest = "sha256:e37d2133c21fae8db1345c653d181f33c85cd2e6ff4c2e4c86d2a0046d8c98fa"
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
      length(terraform_data.gc_pdc_bootstrap) == 0 &&
      length(aws_secretsmanager_secret_version.gc_pdc_token) == 0 &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 0 &&
      toset(keys(aws_secretsmanager_secret_rotation.gc_pdc_token)) == toset(["sprinkler-development", "cooker-development"]) &&
      toset(keys(local.gc_pdc_rotation_triggers)) == toset(["sprinkler-development", "cooker-development"]) &&
      alltrue([for name, trigger in local.gc_pdc_rotation_triggers : (
        trigger.principal == "secretsmanager.amazonaws.com" &&
        trigger.source_account == data.aws_caller_identity.current.account_id &&
        trigger.source_arn == aws_secretsmanager_secret.gc_pdc_token[name].arn
      )]) &&
      length(local.gc_pdc_enrolment_accounts) == 0 &&
      alltrue([for name, rotation in aws_secretsmanager_secret_rotation.gc_pdc_token : (
        rotation.secret_id == aws_secretsmanager_secret.gc_pdc_token[name].id &&
        rotation.rotation_lambda_arn == module.grafana_pdc_token_rotator["this"].lambda_function_arn &&
        rotation.rotate_immediately && one(rotation.rotation_rules).automatically_after_days == 90 &&
        !contains(keys(aws_secretsmanager_secret.gc_pdc_token[name].tags), "pdc:bootstrap")
      )])
    )
    error_message = "Hand off both seeded development accounts; neither must be tagged or invoked for first issuance."
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

run "new_account_without_capable_image_fails_closed" {
  command = plan

  variables {
    rotator = {
      image_digest      = "sha256:7e357f00e83b9c88a320034e0ba7f5ac2cbc7887485b4e1554e1e457fe5d7f8f"
      bootstrap_enabled = false
    }
    accounts = {
      sprinkler-development = { pdc_enabled = true }
      cooker-development    = { pdc_enabled = true }
      new-development       = { pdc_enabled = true }
    }
  }

  expect_failures = [terraform_data.gc_pdc_bootstrap["new-development"]]
}

run "development_first_issuance_accounts_use_readiness_enrolment" {
  command = plan

  variables {
    use_environment_configuration = true
  }

  assert {
    condition = (
      alltrue([for names in [
        keys(terraform_data.gc_pdc_bootstrap), keys(aws_cloudwatch_event_rule.gc_pdc_enrolment),
        keys(aws_cloudwatch_event_target.gc_pdc_enrolment), keys(aws_lambda_permission.gc_pdc_enrolment_tick),
        keys(aws_lambda_permission.gc_pdc_enrolment_rotation), keys(aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery),
        ] : toset(names) == toset([
          "example-development",
          "cloud-platform-development",
      ])]) &&
      alltrue([for name in keys(terraform_data.gc_pdc_bootstrap) : (
        aws_secretsmanager_secret.gc_pdc_token[name].tags["pdc:bootstrap"] == "true" &&
        aws_secretsmanager_secret.gc_pdc_token[name].tags["pdc:rotation-interval-days"] == "90" &&
        aws_secretsmanager_secret.gc_pdc_token[name].tags["pdc:token-ttl-seconds"] == tostring(97 * 86400) &&
        local.gc_pdc_restarter_role_arns[name] == "arn:aws:iam::${local.all_account_ids[name]}:role/grafana-pdc-agent-restarter"
      )]) &&
      length(local.gc_pdc_restarter_role_arns) == 4 &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 0 &&
      length(aws_secretsmanager_secret_version.gc_pdc_token) == 0 &&
      length(aws_lambda_permission.gc_pdc_bootstrap) == 1 &&
      toset(keys(aws_secretsmanager_secret_rotation.gc_pdc_token)) == toset(["sprinkler-development", "cooker-development"])
    )
    error_message = "Only Example and cloud-platform-development get first issuance and readiness ticks; Sprinkler and Cooker must keep their native Terraform schedules."
  }

  assert {
    condition = alltrue([for names in [
      keys(grafana_cloud_private_data_source_connect_network.account), keys(aws_secretsmanager_secret.gc_pdc_token),
      keys(aws_kms_key.gc_pdc_token), keys(aws_kms_alias.gc_pdc_token), keys(aws_secretsmanager_secret_policy.gc_pdc_token),
      keys(data.aws_iam_policy_document.gc_pdc_token_kms), keys(data.aws_iam_policy_document.gc_pdc_token_secret),
      ] : toset(names) == toset([
        "sprinkler-development",
        "cooker-development",
        "example-development",
        "cloud-platform-development",
    ])])
    error_message = "Each opted-in account must have its own network, protected secret, KMS key and alias, and scoped policies."
  }
}

run "reject_unpinned_image" {
  command = plan

  variables {
    rotator = {
      image_digest = "not-a-digest"
    }
  }

  expect_failures = [aws_iam_policy.gc_pdc_rotator["this"]]
}

run "reject_missing_failure_destination" {
  command = plan

  variables {
    rotator = {
      image_digest = "sha256:e37d2133c21fae8db1345c653d181f33c85cd2e6ff4c2e4c86d2a0046d8c98fa"
    }
    failure_alerts = null
  }

  expect_failures = [aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors["this"], aws_cloudwatch_event_target.gc_pdc_rotation_failed["this"]]
}

run "production_common_runtime_without_pdc_accounts" {
  state_key = "empty_rotator"
  command   = apply

  variables {
    environment = "production"
    accounts    = {}
    rotator = {
      image_digest      = "sha256:e37d2133c21fae8db1345c653d181f33c85cd2e6ff4c2e4c86d2a0046d8c98fa"
      bootstrap_enabled = true
    }
  }

  assert {
    condition = (
      toset([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Sid]) ==
      toset(["ReadGrafanaCredential", "ReadStackQueryCredential", "DecryptGrafanaCredential", "DecryptStackQueryCredential", "ManageRotationJournal"]) &&
      alltrue([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : length(s.Resource) > 0 && !contains(s.Resource, "*")]) &&
      length(module.grafana_pdc_token_rotator) == 1 && length(aws_secretsmanager_secret.gc_pdc_rotator_credential) == 2 &&
      length(aws_dynamodb_table.gc_pdc_rotation_state) == 1 && length(aws_cloudwatch_metric_alarm.gc_pdc_rotator_errors) == 1 &&
      length(aws_cloudwatch_event_target.gc_pdc_rotation_failed) == 1 && length(module.gc_pdc_failure_chatbot) == 1 &&
      length(aws_ssm_parameter.gc_pdc_rotator_ecr_repository_uri) == 0 &&
      length(grafana_cloud_private_data_source_connect_network.account) == 0 &&
      length(aws_kms_key.gc_pdc_token) == 0 && length(aws_secretsmanager_secret.gc_pdc_token) == 0 &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 0 &&
      length(aws_secretsmanager_secret_version.gc_pdc_token) == 0 && length(aws_secretsmanager_secret_rotation.gc_pdc_token) == 0 &&
      length(aws_lambda_permission.gc_pdc_bootstrap) == 0 && length(terraform_data.gc_pdc_bootstrap) == 0 &&
      length(local.gc_pdc_rotation_triggers) == 0 && length(local.gc_pdc_enrolment_accounts) == 0 &&
      length(aws_cloudwatch_event_rule.gc_pdc_enrolment) == 0 && length(aws_cloudwatch_event_target.gc_pdc_enrolment) == 0 &&
      length(aws_lambda_permission.gc_pdc_enrolment_tick) == 0 && length(aws_lambda_permission.gc_pdc_enrolment_rotation) == 0 &&
      length(aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery) == 0
    )
    error_message = "Common production resources must need neither a tenant nor wildcard/empty tenant grants."
  }
}

run "new_opt_in_bootstrap_and_tick" {
  state_key = "bootstrap"
  command   = apply

  variables {
    accounts = {
      sprinkler-development = { pdc_enabled = true }
      cooker-development    = { pdc_enabled = true }
      new-development       = { pdc_enabled = true }
    }

    rotator = {
      image_digest      = "sha256:e37d2133c21fae8db1345c653d181f33c85cd2e6ff4c2e4c86d2a0046d8c98fa"
      bootstrap_enabled = true
    }
  }

  assert {
    condition = (
      toset(keys(terraform_data.gc_pdc_bootstrap)) == toset(["new-development"]) &&
      aws_secretsmanager_secret.gc_pdc_token["new-development"].tags["pdc:bootstrap"] == "true" &&
      alltrue([for k in ["sprinkler-development", "cooker-development"] : !contains(keys(aws_secretsmanager_secret.gc_pdc_token[k].tags), "pdc:bootstrap")]) &&
      contains(one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if s.Sid == "RotatePdcSecrets"]), aws_secretsmanager_secret.gc_pdc_token["new-development"].arn) &&
      toset(one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if s.Sid == "AssumeTenantRestarters"])) == toset([
        for id in [1, 2, 8] : "arn:aws:iam::${format("%012d", id)}:role/grafana-pdc-agent-restarter"
      ]) &&
      aws_lambda_permission.gc_pdc_bootstrap["this"].action == "lambda:InvokeFunction" &&
      aws_lambda_permission.gc_pdc_bootstrap["this"].function_name == module.grafana_pdc_token_rotator["this"].lambda_function_arn &&
      aws_lambda_permission.gc_pdc_bootstrap["this"].principal == "arn:aws:iam::@MOCK_PLATFORM_ACCOUNT@:role/github-actions-apply" &&
      length(grafana_cloud_private_data_source_connect_network_token.account) == 0 && length(aws_secretsmanager_secret_version.gc_pdc_token) == 0 &&
      !contains(keys(aws_secretsmanager_secret_rotation.gc_pdc_token), "new-development")
    )
    error_message = "New accounts get one bootstrap action, scoped access, no Terraform token/version and no premature schedule."
  }

  assert {
    condition = (
      toset(keys(local.gc_pdc_enrolment_accounts)) == toset(["new-development"]) &&
      toset(keys(aws_secretsmanager_secret_rotation.gc_pdc_token)) == toset(["sprinkler-development", "cooker-development"]) &&
      toset(keys(local.gc_pdc_rotation_triggers)) == toset(["sprinkler-development", "cooker-development"]) &&
      length(setintersection(keys(local.gc_pdc_enrolment_accounts), keys(local.gc_pdc_rotation_accounts))) == 0
    )
    error_message = "Only the reconciler may schedule a new opt-in; the seeded accounts keep their existing schedules and invoke permissions."
  }

  assert {
    condition = (
      aws_cloudwatch_event_rule.gc_pdc_enrolment["new-development"].schedule_expression == "rate(1 hour)" &&
      aws_cloudwatch_event_target.gc_pdc_enrolment["new-development"].rule == aws_cloudwatch_event_rule.gc_pdc_enrolment["new-development"].name &&
      aws_cloudwatch_event_target.gc_pdc_enrolment["new-development"].arn == local.gc_pdc_function_arn &&
      jsondecode(aws_cloudwatch_event_target.gc_pdc_enrolment["new-development"].input) == {
        Step     = "enrolRotation"
        SecretId = aws_secretsmanager_secret.gc_pdc_token["new-development"].arn
      } &&
      aws_lambda_permission.gc_pdc_enrolment_tick["new-development"].principal == "events.amazonaws.com" &&
      aws_lambda_permission.gc_pdc_enrolment_tick["new-development"].source_arn == aws_cloudwatch_event_rule.gc_pdc_enrolment["new-development"].arn &&
      aws_lambda_permission.gc_pdc_enrolment_rotation["new-development"].principal == "secretsmanager.amazonaws.com" &&
      aws_lambda_permission.gc_pdc_enrolment_rotation["new-development"].source_arn == aws_secretsmanager_secret.gc_pdc_token["new-development"].arn &&
      aws_lambda_permission.gc_pdc_enrolment_rotation["new-development"].source_account == data.aws_caller_identity.current.account_id &&
      alltrue([for permission in [aws_lambda_permission.gc_pdc_enrolment_tick["new-development"], aws_lambda_permission.gc_pdc_enrolment_rotation["new-development"]] :
        permission.action == "lambda:InvokeFunction" && permission.function_name == local.gc_pdc_function_arn
      ])
    )
    error_message = "The hourly tick and both service permissions must address only the intended rule, tenant secret and unqualified rotator."
  }

  assert {
    condition = (
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s if contains(s.Action, "secretsmanager:RotateSecret")]) == {
        Sid       = "EnrolBootstrappedSecrets"
        Effect    = "Allow"
        Action    = ["secretsmanager:RotateSecret"]
        Resource  = [aws_secretsmanager_secret.gc_pdc_token["new-development"].arn]
        Condition = { ArnEquals = { "secretsmanager:RotationLambdaARN" = local.gc_pdc_function_arn } }
      } &&
      one([for s in jsondecode(aws_iam_policy.gc_pdc_rotator["this"].policy).Statement : s.Resource if contains(s.Action, "lambda:InvokeFunction")]) == [local.gc_pdc_function_arn]
    )
    error_message = "The runtime can request rotation only for auto-enrolled secrets and only with its own unqualified ARN."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery["new-development"].metric_name == "FailedInvocations" &&
      aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery["new-development"].dimensions.RuleName == aws_cloudwatch_event_rule.gc_pdc_enrolment["new-development"].name &&
      aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery["new-development"].alarm_actions == toset([aws_sns_topic.gc_pdc_failure_alerts["this"].arn]) &&
      tolist(local.gc_pdc_failure_alarm_arns) == tolist([local.gc_pdc_failure_alarm_arn, "arn:aws:cloudwatch:eu-west-2:@MOCK_PLATFORM_ACCOUNT@:alarm:${aws_cloudwatch_metric_alarm.gc_pdc_enrolment_delivery["new-development"].alarm_name}"]) &&
      tolist(jsondecode(aws_sns_topic_policy.gc_pdc_failure_alerts["this"].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"]) == tolist(local.gc_pdc_failure_alarm_arns) &&
      tolist(one([for s in jsondecode(aws_kms_key.gc_pdc_failure_alerts["this"].policy).Statement : s.Condition.ArnEquals["aws:SourceArn"] if s.Sid == "AllowCloudWatchAlarmToUseKey"])) == tolist(local.gc_pdc_failure_alarm_arns)
    )
    error_message = "EventBridge delivery failures need a rule-specific alarm with permission to use the encrypted alerts topic."
  }
}

run "image_update_after_first_issuance" {
  state_key = "bootstrap"
  command   = apply

  plan_options {
    replace = [aws_cloudwatch_event_target.gc_pdc_enrolment["new-development"]]
  }

  variables {
    accounts = {
      sprinkler-development = { pdc_enabled = true }
      cooker-development    = { pdc_enabled = true }
      new-development       = { pdc_enabled = true }
    }
    rotator = {
      image_digest      = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      bootstrap_enabled = true
    }
  }

  assert {
    condition     = terraform_data.gc_pdc_bootstrap["new-development"].id == run.new_opt_in_bootstrap_and_tick.marker_id
    error_message = "Image upgrades and replacement of the hourly target must preserve the completed bootstrap marker."
  }
}

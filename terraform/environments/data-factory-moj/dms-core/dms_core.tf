moved {
  from = module.dms_core[0]
  to   = module.dms_source_ingestion[0].module.dms_core
}

import {
  for_each = local.dms_core_enabled && local.environment == "development" ? {
    dms_task_logs = {
      module_index    = 0
      log_group_index = 0
      name            = "dms-tasks-data-factory-moj-development-dms-core-dms-instance-development"
    }
  } : {}

  to = module.dms_source_ingestion[each.value.module_index].module.dms_core.aws_cloudwatch_log_group.replication_tasks[each.value.log_group_index]
  id = each.value.name
}

module "dms_source_ingestion" {
  count = local.dms_core_enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/dms-source-ingestion?ref=4eb13e85327e4825b61d36ffe88fa821c3e86324"

  depends_on = [
    aws_iam_role_policy_attachment.dms_vpc,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs
  ]

  name        = "${local.application_name}-${local.environment}-${local.component_name}"
  environment = local.environment
  vpc_id      = data.aws_vpc.shared[0].id

  network = {
    subnet_ids = data.aws_subnets.shared-data[0].ids

    additional_security_group_ids = [
      module.dms_test_harness[0].dms_client_security_group_id
    ]
  }

  replication_instance = {
    instance_class    = "dms.t3.small"
    allocated_storage = 20

    multi_az          = false
    apply_immediately = true
  }

  source_endpoint = {
    engine        = "postgres"
    database_name = module.dms_test_harness[0].source_database_name

    secret_arn         = module.dms_test_harness[0].dms_source_secret_arn
    secret_kms_key_arn = data.aws_kms_key.general_shared.arn

    ssl_mode = "require"
  }

  target = {
    bucket_name   = module.dms_test_harness[0].target_bucket_name
    bucket_folder = "integration-test-full-load-cdc"

    encryption = {
      mode        = "SSE_KMS"
      kms_key_arn = module.dms_test_harness[0].target_kms_key_arn
    }
  }

  replication_tasks = {
    full_load_and_cdc = {
      replication_task_id = "${local.application_name}-${local.environment}-${local.component_name}-full-load-and-cdc"
      migration_type      = "full-load-and-cdc"

      table_mappings = jsonencode({
        rules = [
          {
            "rule-type" = "selection"
            "rule-id"   = "1"
            "rule-name" = "include-public"
            "object-locator" = {
              "schema-name" = "public"
              "table-name"  = "%"
            }
            "rule-action" = "include"
          }
        ]
      })
    }
  }

  tags = local.tags
}

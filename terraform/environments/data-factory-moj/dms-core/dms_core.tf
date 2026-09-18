moved {
  from = module.dms_core[0]
  to   = module.dms_source_ingestion[0].module.dms_core
}

module "dms_source_ingestion" {
  count = local.dms_core_enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/dms-source-ingestion?ref=567e18b4f637ef5935b370286b489cd3a0102cb9"

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

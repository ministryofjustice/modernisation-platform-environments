module "dms_core" {
  count = local.dms_core_enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/dms-core?ref=268b9f51e0e36f3a897cbdd5092751baa11e07b1"

  depends_on = [
    aws_iam_role_policy_attachment.dms_vpc,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs
  ]

  name   = "${local.application_name}-${local.environment}-${local.component_name}"
  vpc_id = data.aws_vpc.shared.id

  replication_instance = {
    replication_instance_id    = "${local.application_name}-${local.environment}-${local.component_name}"
    replication_instance_class = "dms.t3.small"
    allocated_storage          = 20

    subnet_ids = data.aws_subnets.shared-data.ids

    multi_az          = false
    apply_immediately = true
  }

  security_group = {
    additional_vpc_security_group_ids = [
      module.dms_test_harness[0].dms_client_security_group_id
    ]
  }

  source_endpoint = {
    endpoint_id = "${local.application_name}-${local.environment}-${local.component_name}-source"
    engine_name = "postgres"

    database_name = module.dms_test_harness[0].source_database_name

    secrets_manager_arn = module.dms_test_harness[0].dms_source_secret_arn

    ssl_mode = "require"
  }

  s3_target_endpoint = {
    endpoint_id = "${local.application_name}-${local.environment}-${local.component_name}-target"
    bucket_name = module.dms_test_harness[0].target_bucket_name

    bucket_folder = "integration-test"

    compression_type = "GZIP"
    data_format      = "parquet"

    encryption_mode                    = "SSE_KMS"
    server_side_encryption_kms_key_arn = module.dms_test_harness[0].target_kms_key_arn
  }

  replication_tasks = {
    full_load = {
      replication_task_id = "${local.application_name}-${local.environment}-${local.component_name}-full-load"
      migration_type      = "full-load"

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

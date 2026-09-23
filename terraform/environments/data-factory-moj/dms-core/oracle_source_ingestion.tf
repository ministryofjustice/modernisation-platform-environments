module "oracle_source_ingestion" {
  count = local.dms_core_enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/dms-source-ingestion?ref=815c95f2c6019e49e7de9cb27a6a028e70a6fccc"

  depends_on = [
    aws_iam_role_policy_attachment.dms_vpc,
    aws_iam_role_policy_attachment.dms_cloudwatch_logs,
    module.oracle_test_harness
  ]

  name        = "${local.application_name}-${local.environment}-oracle"
  environment = local.environment
  vpc_id      = data.aws_vpc.shared[0].id

  network = {
    subnet_ids = data.aws_subnets.shared-data[0].ids

    additional_security_group_ids = [
      module.oracle_test_harness[0].dms_client_security_group_id
    ]
  }

  replication_instance = {
    instance_class    = "dms.t3.small"
    allocated_storage = 20

    multi_az          = false
    apply_immediately = true
  }

  source_endpoint = {
    engine        = "oracle"
    database_name = module.oracle_test_harness[0].source_database_name

    secret_arn         = module.oracle_test_harness[0].dms_source_secret_arn
    secret_kms_key_arn = data.aws_kms_key.general_shared.arn

    ssl_mode = "none"

    extra_connection_attributes = "useLogminerReader=Y"
  }

  target = {
    bucket_name   = module.oracle_test_harness[0].target_bucket_name
    bucket_folder = "oracle-integration-test-full-load-cdc"

    encryption = {
      mode        = "SSE_KMS"
      kms_key_arn = module.oracle_test_harness[0].target_kms_key_arn
    }
  }

  replication_tasks = {
    full_load_and_cdc = {
      replication_task_id = "${local.application_name}-${local.environment}-oracle-full-load-and-cdc"
      migration_type      = "full-load-and-cdc"

      table_mappings = jsonencode({
        rules = [
          {
            "rule-type" = "selection"
            "rule-id"   = "1"
            "rule-name" = "include-oracle-integration-test"
            "object-locator" = {
              "schema-name" = "DMS_USER"
              "table-name"  = "DMS_INTEGRATION_TEST"
            }
            "rule-action" = "include"
          }
        ]
      })
    }
  }

  tags = local.tags
}
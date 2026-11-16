module "onboarding_replication_capacity" {
  count = local.dms_core_enabled ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/database-migration-service/modules/dms-replication-capacity?ref=296c2060d38b1dab02d2560f4c058201ac2b757f"

  name   = "${local.application_name}-${local.environment}-onboarding"
  vpc_id = data.aws_vpc.shared[0].id

  replication_instance = {
    replication_instance_id    = "${local.application_name}-${local.environment}-onboarding"
    replication_instance_class = "dms.t3.small"
    allocated_storage          = 20
    multi_az                   = false
    kms_key_arn                = data.aws_kms_key.general_shared.arn

    subnet_ids = sort(tolist(data.aws_subnets.shared-data[0].ids))
  }

  security_group = {
    additional_vpc_security_group_ids = sort(distinct([
      for source in values(local.onboarding_sources) :
      source.security_group_id
    ]))
  }

  task_logging = {
    enabled           = true
    retention_in_days = 30
  }

  create_task_log_group = true

  tags = local.tags
}

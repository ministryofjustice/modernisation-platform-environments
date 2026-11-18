module "configured_ingestion" {
  count = local.is-development ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/database-migration-service/modules/configured-ingestion?ref=64edea3af40e86b6a48fd005db4edd743955c592"

  name_prefix = "dfmoj-ingestion"

  compiled_artifacts = try(var.deployment.compiled_artifacts, {})
  contract_catalogs  = try(var.deployment.contract_catalogs, {})
  contract_runtimes  = try(var.deployment.contract_runtimes, {})
  runtime_settings   = try(var.deployment.runtime_settings, {})

  artifact             = try(var.deployment.artifact, null)
  registry             = try(var.deployment.registry, null)
  registry_kms_key_arn = "arn:aws:kms:eu-west-2:110695445580:key/a1d0c432-5563-4b74-b463-bd0f4458fdd8"

  replication_capacities = try(var.deployment.replication_capacities, {})
  capacity_assignments   = try(var.deployment.capacity_assignments, {})

  log_retention_days = 30
  tags               = local.tags
}

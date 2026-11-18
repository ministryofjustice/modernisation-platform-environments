module "configured_ingestion" {
  count = local.is-development ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/database-migration-service/modules/configured-ingestion?ref=a9f1a8b97f297fd9c9ea435e886fc648b0fa5491"

  name_prefix = "dfmoj-ingestion"

  compiled_artifacts = try(var.deployment.compiled_artifacts, {})
  contract_catalogs  = try(var.deployment.contract_catalogs, {})
  contract_runtimes  = try(var.deployment.contract_runtimes, {})
  runtime_settings   = try(var.deployment.runtime_settings, {})

  artifact = try(var.deployment.artifact, null)
  registry = try(var.deployment.registry, null)

  replication_capacities = try(var.deployment.replication_capacities, {})
  capacity_assignments   = try(var.deployment.capacity_assignments, {})

  log_retention_days = 30
  tags               = local.tags
}

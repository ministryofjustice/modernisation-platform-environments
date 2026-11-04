module "configured_ingestion" {
  count = local.is-development ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/database-migration-service/modules/configured-ingestion?ref=c7b03021b809f7c0b2809c2faedd14baaf9f45f8"

  name_prefix = "dfmoj-ingestion"

  compiled_artifacts = try(var.deployment.compiled_artifacts, {})
  runtime_settings   = try(var.deployment.runtime_settings, {})

  artifact = try(var.deployment.artifact, null)
  registry = try(var.deployment.registry, null)

  replication_capacities = try(var.deployment.replication_capacities, {})
  capacity_assignments   = try(var.deployment.capacity_assignments, {})

  log_retention_days = 30
  tags               = local.tags
}

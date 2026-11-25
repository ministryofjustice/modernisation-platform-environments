module "configured_ingestion" {
  count = local.is-development ? 1 : 0

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/database-migration-service/modules/configured-ingestion?ref=7b92d70e62e928296bf9efa3d780111ee59004ba"

  name_prefix = "dfmoj-ingestion"

  raw_batch_handoffs = local.is-development ? jsondecode(
    file("${path.module}/raw-batch-handoffs.json")
  ) : {}


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

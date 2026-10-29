output "contract_deployment_references" {
  description = "Deployed contract capabilities for building revision-specific integration catalogs; does not approve contracts."
  sensitive   = true

  value = local.contract_management_enabled ? {
    registration = local.registration_enabled ? {
      kind = "lambda"
      arn  = module.schema_registration[0].function_arn
    } : null

    registry = local.registration_enabled ? {
      table_name = module.schema_registration[0].contract_table_name
      arn        = module.schema_registration[0].contract_table_arn
    } : null

    generation = {
      for name, deployment in module.schema_generation : name => {
        kind          = "lambda"
        arn           = deployment.function_arn
        source        = local.generation_sources[name].service
        database_name = local.generation_sources[name].database_name
        schema_name   = local.generation_sources[name].schema_name
        table_names   = local.generation_sources[name].table_names
      }
    }

    validation = {
      for name, deployment in module.schema_validation : name => {
        kind            = "lambda"
        arn             = deployment.function_arn
        source_mappings = local.validation_deployments[name].source_mappings
      }
    }
  } : null
}

output "deployments" {
  description = "Compiled artifacts, actual resource bindings and runtime references for verified publication."
  sensitive   = true

  value = local.is-development ? module.configured_ingestion[0].deployments : null
}

output "retained_inventory" {
  description = "Previously deployed compiler artifacts to retain unchanged when preparing another deployment."
  sensitive   = true

  value = local.is-development ? module.configured_ingestion[0].retained_inventory : null
}

output "deployed_capacity_assignments" {
  description = "Capacity assignments to preserve for retained extraction generations."
  sensitive   = true

  value = local.is-development ? try(var.deployment.capacity_assignments, null) : null
}

output "deployment_provenance" {
  description = "Compiler and runtime package references used by this deployment."
  sensitive   = true

  value = local.is-development && var.deployment != null ? {
    compiler_commit = var.deployment.compiler_commit
    artifact        = var.deployment.artifact
  } : null
}

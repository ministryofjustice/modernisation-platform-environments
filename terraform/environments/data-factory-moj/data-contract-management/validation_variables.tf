variable "validation_deployments_by_environment" {
  description = "Schema-validation deployments by environment. Source mappings will later come from service YAML configuration."

  type = map(map(object({
    image_uri      = string
    architecture   = optional(string, "arm64")
    ingestion_type = string

    source_mappings = list(object({
      bucket_name   = string
      prefix        = string
      source        = string
      database_name = string
      schema_name   = string
      table_name    = string
    }))

    incoming_kms_key_arns = optional(set(string), [])

    timeout_seconds                = optional(number, 120)
    memory_size_mb                 = optional(number, 512)
    reserved_concurrent_executions = optional(number, 5)

    alarm_action_arns = optional(list(string), [])
  })))

  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for deployments in values(var.validation_deployments_by_environment) : [
        for deployment_key in keys(deployments) :
        can(regex("^[a-z0-9][a-z0-9-]{0,20}$", deployment_key))
      ]
    ]))
    error_message = "Validation deployment keys must be 1–21 characters using lowercase letters, numbers and hyphens, starting with a letter or number."
  }

  validation {
    condition = alltrue(flatten([
      for deployments in values(var.validation_deployments_by_environment) : [
        for deployment in values(deployments) :
        can(regex("^[^\\s]+@sha256:[a-f0-9]{64}$", deployment.image_uri))
      ]
    ]))
    error_message = "Each validation image_uri must be pinned to a SHA-256 digest."
  }

  validation {
    condition = alltrue(flatten([
      for deployments in values(var.validation_deployments_by_environment) : [
        for deployment in values(deployments) :
        contains(["arm64", "x86_64"], deployment.architecture) &&
        contains(["FULL", "CDC"], deployment.ingestion_type)
      ]
    ]))
    error_message = "Architecture must be arm64 or x86_64, and ingestion_type must be FULL or CDC."
  }

  validation {
    condition = alltrue(flatten([
      for deployments in values(var.validation_deployments_by_environment) : [
        for deployment in values(deployments) :
        length(deployment.source_mappings) > 0
      ]
    ]))
    error_message = "Each validation deployment must have at least one source mapping."
  }
}

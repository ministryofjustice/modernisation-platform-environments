variable "generation_sources_by_environment" {
  description = "Schema generation source configurations, grouped by environment."
  type = map(map(object({
    engine              = string
    service             = string
    database_name       = string
    schema_name         = string
    table_names         = list(string)
    secret_arn          = string
    secret_kms_key_arns = optional(set(string), [])
    oracle_service_name = optional(string)
    oracle_sid          = optional(string)

    contract_namespace     = string
    contract_version       = string
    contract_object_prefix = string
    contract_contacts      = optional(map(string), {})

    image_uri    = string
    architecture = optional(string, "arm64")

    vpc_id                     = string
    subnet_ids                 = set(string)
    database_security_group_id = string
    database_port              = number

    timeout_seconds                = optional(number, 300)
    memory_size_mb                 = optional(number, 512)
    reserved_concurrent_executions = optional(number, 2)
    alarm_action_arns              = optional(list(string), [])
  })))

  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for sources in values(var.generation_sources_by_environment) : [
        for source_key in keys(sources) :
        can(regex("^[a-z0-9][a-z0-9-]{0,15}$", source_key))
      ]
    ]))
    error_message = "Source keys must be 1–16 lowercase letters, numbers or hyphens, starting with a letter or number."
  }

  validation {
    condition = alltrue(flatten([
      for sources in values(var.generation_sources_by_environment) : [
        for source_config in values(sources) :
        contains(["postgres", "oracle"], source_config.engine)
      ]
    ]))
    error_message = "Each source engine must be postgres or oracle."
  }

  validation {
    condition = alltrue(flatten([
      for sources in values(var.generation_sources_by_environment) : [
        for source_config in values(sources) :
        can(regex(
          "^[^\\s]+@sha256:[a-f0-9]{64}$",
          source_config.image_uri
        ))
      ]
    ]))
    error_message = "Each image URI must be pinned to a SHA-256 digest."
  }

  validation {
    condition = alltrue(flatten([
      for sources in values(var.generation_sources_by_environment) : [
        for source_config in values(sources) :
        source_config.database_port >= 1 &&
        source_config.database_port <= 65535 &&
        floor(source_config.database_port) == source_config.database_port
      ]
    ]))
    error_message = "Database ports must be integers between 1 and 65535."
  }
}

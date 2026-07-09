variable "database_name" {
  description = "Name of the Glue Catalog database."
  type        = string
}

variable "database_description" {
  description = "Description of the Glue Catalog database."
  type        = string
  default     = null
}

variable "tables" {
  description = "Glue table definitions."
  type = map(object({
    description = optional(string)

    s3_location = string

    input_format          = optional(string)
    output_format         = optional(string)
    serialization_library = optional(string)

    parameters = optional(map(string), {})

    columns = list(object({
      name    = string
      type    = string
      comment = optional(string)
    }))

    partition_keys = optional(list(object({
      name    = string
      type    = string
      comment = optional(string)
    })), [])
  }))
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default     = {}
}
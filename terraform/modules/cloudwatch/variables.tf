variable "environment" {
  # tflint-ignore: terraform_typed_variables
  # Not defining 'type' as it is defined in the output of the environment module
  description = "Standard environmental data resources from the environment module"
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_cloudwatch_dashboard = optional(bool, false)
  })
}

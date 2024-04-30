variable "environment" {
  # tflint-ignore: terraform_typed_variables
  # Not defining 'type' as it is defined in the output of the environment module
  description = "Standard environmental data resources from the environment module"
}

variable "source_account_ids" {
  type    = list(string)
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_cloudwatch_monitoring_account    = optional(bool, false)
    enable_cloudwatch_cross_account_sharing = optional(bool, false)
  })
}

variable "monitoring_account_sink_identifier" {
  type    = string
  default = "arn:aws:oam:eu-west-2:775245656481:sink/7d4f9ba0-e432-49d1-8f34-1fda2d165bf8"
}

variable "monitoring_account_id" {
  type    = string
}

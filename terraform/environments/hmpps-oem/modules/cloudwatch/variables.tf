variable "source_account_ids" {
  type = list(string)
  default = ["612659970365", "546088120047"]
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_cloudwatch_monitoring_account = optional(bool, false)
  })
}

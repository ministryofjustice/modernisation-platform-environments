variable "source_account_ids" {
  type    = list(string)
  default = ["612659970365", "546088120047"] #nomis-test and oasys-test
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_cloudwatch_monitoring_account = optional(bool, false)
    enable_cloudwatch_cross_account_sharing = optional(bool, false)
  })
}
variable "monitoring_account_sink_identifier" {
  type    = string
  default = "arn:aws:oam:eu-west-2:775245656481:sink/c2161e14-4683-4d84-ae2e-1eb7385e715b"
}

variable "monitoring_account_id" {
  type    = string
  default = "775245656481" # hmpps-oem-test account
}

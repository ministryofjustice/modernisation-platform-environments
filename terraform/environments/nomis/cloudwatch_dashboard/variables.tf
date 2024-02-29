variable "monitoring_account_sink_identifier" {
  type = string
  default = "arn:aws:oam:eu-west-2:775245656481:sink/c2161e14-4683-4d84-ae2e-1eb7385e715b"
}

variable "monitoring_account_id" {
  type = string
  default = "775245656481" # hmpps-oem-test account
}

variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_hmpps-oem_monitoring = optional(bool, false)
  })
}
variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_hmpps-oem_monitoring = optional(bool, false)
    enable_cloudwatch_dashboard = optional(bool, false)
  })
}

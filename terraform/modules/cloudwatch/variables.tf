variable "options" {
  description = "Map of options controlling what resources to return"
  type = object({
    enable_cloudwatch_dashboard = optional(bool, false)
  })
}

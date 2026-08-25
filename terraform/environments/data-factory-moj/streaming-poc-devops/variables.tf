variable "report_schedule" {
  description = "EventBridge Scheduler expression for how often to generate the Inspector findings report. Defaults to daily."
  type        = string
  default     = "rate(1 day)"
}

variable "report_format" {
  description = "Format for the Inspector findings report. Valid values are JSON or CSV."
  type        = string
  default     = "CSV"
  validation {
    condition     = contains(["JSON", "CSV"], var.report_format)
    error_message = "report_format must be JSON or CSV."
  }
}

variable "inspector_filters" {
  description = <<-EOT
    Optional Inspector filter criteria passed directly to CreateFindingsReport.
    Keys map to Inspector2 FilterCriteria fields, values are lists of objects with 'comparison' and 'value'.
    Example:
      inspector_filters = {
        severity = [{ comparison = "EQUALS", value = "HIGH" }, { comparison = "EQUALS", value = "CRITICAL" }]
      }
  EOT
  type        = map(list(object({ comparison = string, value = string })))
  default     = {}
}

variable "report_schedule" {
  description = "EventBridge Scheduler expression for how often to generate the Inspector findings report. Defaults to daily."
  type        = string
  default     = "rate(1 day)"
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

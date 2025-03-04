
variable "dpr_event_bus_name" {
  description = "Name of the custom event bus"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the log group."
  type        = map(any)
  default     = {}
}
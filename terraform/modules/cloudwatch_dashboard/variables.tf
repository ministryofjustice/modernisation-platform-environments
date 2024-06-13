variable "accountId" {
  description = "For monitoring accounts, apply this accountId to all widgets in dashboard"
  type        = string
  default     = null
}

variable "dashboard_name" {
  description = "The name of the dashboard"
  type        = string
}

variable "periodOverride" {
  description = "Use this field to specify the period for the graphs when the dashboard loads. Specifying auto causes the period of all graphs on the dashboard to automatically adapt to the time range of the dashboard. Specifying inherit ensures that the period set for each graph is always obeyed."
  type        = string
  default     = null
}

variable "start" {
  description = "The start of the time range to use for each widget on the dashboard, e.g. -PT3H for last 3 hours"
  type        = string
  default     = null
}

variable "widget_groups" {
  description = "list of objects defining a group of widgets. Automatically include a text widget if header_markdown defined. See README.md"
  # tflint-ignore: terraform_typed_variables
  # type = list(object({  
  #   header_markdown = optional(string)     # include a header text widget if set
  #   width           = number               # width of each widget, must be divisor of 24
  #   height          = number               # height of each widget
  #   widgets         = list(any)            # as per https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html
  # }))
  default = []
}

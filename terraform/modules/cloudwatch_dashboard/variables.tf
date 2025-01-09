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

# tflint-ignore: terraform_typed_variables
variable "ec2_instances" {
  description = "A map of existing modernisation-platform-terraform-ec2-instance resources. Required if using search filtering or iops/throughput widgets"
  default     = {}
}

# tflint-ignore: terraform_typed_variables
variable "widget_groups" {
  description = "list of objects defining a group of widgets. Automatically include a text widget if header_markdown defined. See README.md"
  # type = list(object({
  #   header_markdown = optional(string)     # include a header text widget if set
  #   width           = number               # width of each widget, must be divisor of 24
  #   height          = number               # height of each widget
  #   accountId       = optional(string)     # for monitoring accounts, apply this accountId to all widgets in group
  #   search_filter   = optional(object({    # optionally apply filter to each 'expression' widget
  #     negate        = bool                 # negate the filter, e.g. add NOT to the expression
  #     ec2_instance = optional(list(string)) # provide list of EC2 InstanceIds
  #     ec2_tag      = optional(list(object({ # select EC2s with given tag name and value
  #       name = string
  #       value = string
  #     })))
  #   }))
  #   search_filter_dimension = optional(object({ # optionally apply filter to each 'expression' widget
  #     negate = optional(bool) # negate the filter, e.g. add NOT to the expression
  #     name   = string         # the name of the dimension to filter
  #     values = list(string)   # list of dimension values
  #   }))
  #   add_ebs_widgets = optional(object({
  #     iops = bool                          # add additional widgets showing EBS IOPS vs configured max
  #     throughput = bool                    # add additional widgets showing EBS thoughput vs configured max
  #   }))
  #   widgets         = list(any)            # as per https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Dashboard-Body-Structure.html
  #   NOTE: widget can also use following fields for module only
  #     expression        = string # automatically create metrics[] with expression
  #     expression_math   = string # if additional maths need to be applied to the expression
  #     expression_period = number # optionally fix the time period
  #     search_filter     = string # additional search filter, e.g. InstanceId=(i-05a8b662eb6a6a5f6 OR i-065e9f701ab8fda22)
  #                                                           NOT InstanceId=(i-05a8b662eb6a6a5f6 OR i-065e9f701ab8fda22)
  #     alarm_threshold = number # automatically create horizontal annotation (if supported)
  # }))
  default = []
}

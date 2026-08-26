variable "log_groups" {
  description = "Specific log groups to use with the query (Optional)"
  type        = list(string)
  default     = []
}

variable "query" {
  description = "CW Log Query Definition, Multiline"
  type        = string
  default     = <<EOH
This is my multi-line string, with a newline before and a newline after.
EOH
}

variable "query_name" {
  description = "Query Name"
  type        = string
  default     = ""
}

variable "create_cw_insight" {
  description = "Whether to create the Cloudwatch Insights Definition"
  type        = bool
  default     = false
}
variable "log_group_name" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  tags              = var.tags
}

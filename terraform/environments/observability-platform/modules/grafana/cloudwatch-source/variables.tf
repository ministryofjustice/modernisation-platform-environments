variable "name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "cloudwatch_custom_namespaces" {
  type    = string
  default = ""
}

variable "xray_enabled" {
  type    = bool
  default = false
}

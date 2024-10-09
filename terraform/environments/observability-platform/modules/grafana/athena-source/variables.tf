variable "name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "athena_enabled" {
  type    = bool
  default = false
}

variable "athena_config" {
  type = map(object({
    database  = string
    workgroup = string
  }))
}

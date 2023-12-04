variable "name" {
  type = string
}

variable "environment_management" {
  type = object({
    account_ids = map(string)
  })
}

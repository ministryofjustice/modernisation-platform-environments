variable "role_name_suffix" {
  type     = string
  nullable = false
}

variable "role_description" {
  type     = string
  nullable = false
}

variable "iam_policy_document" {
  type     = list(string)
  nullable = false
}

variable "role_name_suffix" {
  type     = string
  nullable = false
}

variable "role_description" {
  type     = string
  nullable = false
}

variable "iam_policy_document" {
  type     = string
  nullable = false
}

variable "secret_code" {
  type     = string
  nullable = false
}

variable "oidc_arn" {
  type     = string
  nullable = false
}

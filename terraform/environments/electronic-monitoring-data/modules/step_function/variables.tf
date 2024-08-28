variable "name" {
    type = string
    nullable = false
}

variable "iam_policies" {
  type = map(object({
    arn  = string
  }))
  nullable = false
}

variable "env_account_id" {
    type = string
    nullable = false
}

variable "variable_dictionary" {
    type = map
    nullable = false
}
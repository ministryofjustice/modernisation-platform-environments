variable "name" {
    type = string
    nullable = false
}

variable "iam_role" {
  type = object({
    name = string
    arn  = string
    id   = string
  })
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
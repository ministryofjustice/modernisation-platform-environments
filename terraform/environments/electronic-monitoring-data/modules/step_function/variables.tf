variable "name" {
  type     = string
  nullable = false
}

variable "iam_policies" {
  type = map(object({
    arn = string
  }))
  nullable = false
}

variable "variable_dictionary" {
  type     = map(any)
  nullable = false
}

variable "type" {
  type     = string
  nullable = true
  default  = "STANDARD"
}

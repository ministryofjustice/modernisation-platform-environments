variable "env_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "extra_task_role_policies" {
  type        = map(any)
  default     = {}
  description = "A list of data \"aws_iam_policy_document\""
}

variable "extra_service_role_allow_statements" {
  type    = list(string)
  default = []
}

variable "extra_exec_role_allow_statements" {
  type    = list(string)
  default = []
}

variable "BRANCH_NAME" {
  type        = string
  default     = "main"
  description = "Github actions running branch"
}

 # tflint-ignore: terraform_unused_declarations
  type        = string
  default     = ""
  description = "GH username triggering Github action"
}

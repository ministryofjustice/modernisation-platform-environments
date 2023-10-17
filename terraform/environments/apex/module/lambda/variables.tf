variable "backup_policy_name" {
  type        = string
  description = "backup iam policy name"
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
}

variable "source_file" {
  type        = list(string)
  description = "source file for Function"
  default     = [""]
}

variable "filename" {
  type        = list(string)
  description = "Function filename"
  default     = [""]
}

variable "output_path" {
  type        = list(string)
  description = "Function filename"
  default     = [""]
}



variable "function_name" {
   type        = list(string)
  description = "Function name"
  default     = [""]
}

variable "handler" {
  type        = string
  description = "Function handler"
  default     = ""
}
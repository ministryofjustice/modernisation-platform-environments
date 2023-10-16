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
  type        = string
  description = "source file for Function"
  default     = ""
}

variable "output_path" {
  type        = string
  description = "output path to zip file Function"
  default     = ""
}

variable "filename" {
  type        = string
  description = "Function filename"
  default     = ""
}

variable "function_name" {
  type        = string
  description = "Function function name"
  default     = ""
}

variable "handler" {
  type        = string
  description = "Function handler"
  default     = ""
}
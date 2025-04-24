variable "project_name" {
  description = "Project prefix for the log group"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, preprod, prod)"
  type        = string
}

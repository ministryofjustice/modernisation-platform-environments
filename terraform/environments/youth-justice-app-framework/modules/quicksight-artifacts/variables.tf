variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {}
}

variable "vpc_connection_arn" {
  type        = string
  description = "The arn of the Quicksight VPC Connection."
}

variable "quicksight_role_name" {
  type        = string
  description = "The name of the role to be assined tot he Quicksight VPN Connection."
  default     = "aws-quicksight-service-role-v0"
}

variable "redshift_host" {
  type        = string
  description = "The Redshift host name."
}

variable "redshift_port" {
  type        = string
  description = "The Redshift Port."
}

variable "redshift_quicksight_user_secret_arn" {
  type        = string
  description = "The ARN of the secret crated for the Quicksight user in Redshift."
}

variable "postgres_host" {
  type        = string
  description = "The Postgres database host name."
}

variable "postgres_port" {
  type        = string
  description = "The Postgres databases Port."
}

variable "postgres_quicksight_user_secret_arn" {
  type        = string
  description = "The ARN of the secret created for the Quicksight user in Postgres."
}



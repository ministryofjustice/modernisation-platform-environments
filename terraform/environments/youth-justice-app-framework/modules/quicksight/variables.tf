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

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "database_subnet_ids" {
  description = "List of database subnets"
  type        = list(string)
}

variable "postgresql_sg_id" {
  type        = string
  description = "The ID of the RDS PostgreSQL Security Group. Used to add a rule to enable Quicksight access to PostgreSQL."
}

variable "redshift_sg_id" {
  type        = string
  description = "The ID of the Redshift Serverless Security Group. Used to add a rule to enable Quicksight access to Redshift."
}



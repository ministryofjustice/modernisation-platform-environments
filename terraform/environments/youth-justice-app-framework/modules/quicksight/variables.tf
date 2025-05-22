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

variable "notification_email" {
  type        = string
  description = "Mail address that you want Amazon QuickSight to send notifications to regarding your Amazon QuickSight account or Amazon QuickSight subscription"
  default     = "YJAFoperationsAWS@necsws.com"
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


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

variable "notification_email {
  type        = string
  description = "Mail address that you want Amazon QuickSight to send notifications to regarding your Amazon QuickSight account or Amazon QuickSight subscription"
  default     = "YJAFoperationsAWS@necsws.com"
}

variable "vpc_connection_id {
  type        = string
  description = "The ID of the VPC connection to be created in Quicksight."
}

variable "quicksight_role_name {
  type        = string
  description = "The name of the role to be assined tot he Quicksight VPN Connection."
  default     = "aws-qiicksight-service-role-v0"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}


variable "database_subnets" {
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

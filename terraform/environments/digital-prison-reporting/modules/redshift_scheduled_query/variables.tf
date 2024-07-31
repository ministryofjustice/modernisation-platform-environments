variable "project_id" {
  type        = string
  description = "Project ID"
}

variable "env" {
  type        = string
  description = "Env Type"
}

variable "name" {
  type        = string
  description = "Name of the scheduled query (for use in resource names)"
}

variable "description" {
  type        = string
  description = "Description of the scheduled query (for use in resource descriptions)"
  default = ""
}

variable "schedule_expression" {
  type        = string
  description = "An EventBridge schedule expression (e.g. `rate(1 hour)`, `cron(0 12 * * ? *)`), as per https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html"
}

variable "redshift_cluster_arn" {
  type        = string
  description = "The ARN of the target RedShift cluster"
}

variable "redshift_database_name" {
  type        = string
  description = "The name of the target RedShift database"
}

variable "redshift_secrets_manager_arn" {
  type        = string
  description = "The name or ARN of the secret that enables access to the RedShift cluster"
}

variable "sql_statement" {
  type        = string
  description = "The SQL statement text to run"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

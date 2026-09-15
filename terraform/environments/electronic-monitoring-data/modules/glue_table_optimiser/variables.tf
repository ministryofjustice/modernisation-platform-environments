variable "databases" {
  type = set(string)
}

variable "optimizer_bucket_id" {
  type = string
}

variable "table_optimizer_defaults" {
  type = object({
    min_input_files                        = number
    delete_file_threshold                  = number
    snapshot_retention_period_in_days      = number
    number_of_snapshots_to_retain          = number
    orphan_file_retention_period_in_days   = number
    retention_run_rate_in_hours            = number
    orphan_file_deletion_run_rate_in_hours = number
  })

  default = {
    min_input_files                        = 100
    delete_file_threshold                  = 1
    snapshot_retention_period_in_days      = 7
    number_of_snapshots_to_retain          = 3
    orphan_file_retention_period_in_days   = 7
    retention_run_rate_in_hours            = 24
    orphan_file_deletion_run_rate_in_hours = 24
  }
}

variable "compaction_excluded_tables" {
  description = "Fully qualified database.table names to exclude from Glue table compaction."
  type        = set(string)
  default     = []
}

variable "role_arn" {
  type = string
}

variable "environment" {
  type = string
}

variable "dbt_databases" {
  type    = set(string)
  default = []
}


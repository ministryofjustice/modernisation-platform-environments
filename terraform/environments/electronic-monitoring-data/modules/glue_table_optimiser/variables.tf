variable "databases" {
  type = set(string)
}

variable "optimizer_bucket_id" {
  type = string
}

variable "orphan_prefix_overrides_by_database" {
  type    = map(string)
  default = {}
}

variable "table_optimizer_defaults" {
  type = object({
    snapshot_retention_period_in_days      = number
    number_of_snapshots_to_retain          = number
    orphan_file_retention_period_in_days   = number
    retention_run_rate_in_hours            = number
    orphan_file_deletion_run_rate_in_hours = number
  })

  default = {
    snapshot_retention_period_in_days      = 7
    number_of_snapshots_to_retain          = 3
    orphan_file_retention_period_in_days   = 7
    retention_run_rate_in_hours            = 24
    orphan_file_deletion_run_rate_in_hours = 24
  }
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

variable "dbt_domain_name_by_database" {
  type    = map(string)
  default = {}
}

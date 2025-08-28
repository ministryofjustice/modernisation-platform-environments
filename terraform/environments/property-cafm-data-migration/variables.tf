# variables.tf
variable "ingestion_account_ids" {
  description = "Map of short env code -> ingestion AWS account ID"
  type        = map(string)
  default     = {
    dev  = local.environment_management.account_ids["analytical-platform-ingestion-development"]
    prod = local.environment_management.account_ids["analytical-platform-ingestion-production"]
    # preprod => no ingestion policy created there
  }
}

variable "ingestion_role_name" {
  type    = string
  default = "transfer"
}
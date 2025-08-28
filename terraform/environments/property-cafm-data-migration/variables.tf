# variables.tf
variable "ingestion_account_ids" {
  description = "Map of short env code -> ingestion AWS account ID"
  type        = map(string)
  default     = {}
}

variable "ingestion_role_name" {
  type    = string
  default = "transfer"
}
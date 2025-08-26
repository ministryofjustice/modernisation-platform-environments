# variables.tf
variable "ingestion_account_ids" {
  description = "Map of short env code -> ingestion AWS account ID"
  type        = map(string)
  default     = {
    dev  = "730335344807"
    prod = "471112983409"
    # preprod => no ingestion policy created there
  }
}

variable "ingestion_role_name" {
  type    = string
  default = "transfer"
}
variable "bucket_name" {
  type        = string
  default     = "coat-${local.environment}-cur-v2-hourly"
  description = "Bucket name to use depending on the environment"
}

variable "enriched_bucket_name" {
  type        = string
  default     = "coat-${local.environment}-cur-v2-hourly-enriched"
  description = "Bucket name for GreenPixie enriched data"
}

variable "environment" {
  type        = string
  default     = local.environment
  description = "Environment which is being deployed in"
}

variable "account_id" {
  type        = string
  default     = data.aws_caller_identity.current.account_id
  description = "Account ID of the account performing the action"
}

variable "root_account_id" {
  type        = string
  default     = local.environment_management.aws_organizations_root_account_id
  description = "ID of the Management account"
}

variable "cross_env_account_id" {
  type        = string
  default     = local.coat_prod_account_id
  description = "ID of the Coat production account"
}

variable "prod_environment" {
  type        = string
  default     = local.prod_environment
  description = "Explicit calling of Prod environment used in the cross environment account ID string"
}
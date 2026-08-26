variable "ingestion_domain_name" {
  description = "Name of the ingestion domain, e.g. prb-some-service for Probation services, dps-some-service for DPS services"
  type        = string
}

variable "project_id" {
  type        = string
  description = "Project Short ID that will be used in naming resources"
}

variable "cloud_platform_shared_kms_key_id" {
  description = "This KMS key ID or ARN is used to encrypt the secret if cloud platform should have access to this secret."
  type        = string
}

variable "cloud_platform_aws_account_id" {
  description = "AWS account ID of the cloud platform"
  type        = string
}

variable "is_cloud_platform_accessible" {
  description = "Whether the Cloud Platform AWS account should be granted access to the secret or not"
  type        = bool
  default     = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

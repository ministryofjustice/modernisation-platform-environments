variable "ds_managed_ad_directory_name" {
  type        = string
  description = "The fully qualified domain name for the AWS Managed Microsoft AD directory, such as corp.example.com"
}

variable "ds_managed_ad_edition" {
  type        = string
  default     = "Standard"
  description = "The AWS Managed Microsoft AD edition: Enterprise or Standard (default)"
  validation {
    condition     = contains(["Enterprise", "Standard"], var.ds_managed_ad_edition)
    error_message = "The edition value must be Enterprise or Standard."
  }
}

variable "ds_managed_ad_secret_key" {
  type        = string
  default     = "aws/secretsmanager"
  description = "ARN or Id of the AWS KMS key to be used to encrypt the secret values in the versions stored in this secret"
}

variable "ds_managed_ad_short_name" {
  type        = string
  description = "The NetBIOS name for the AWS Managed Microsoft AD directory, such as CORP"
}

variable "ds_managed_ad_subnet_ids" {
  type        = list(string)
  description = "Two private subnet IDs for the AWS Managed Microsoft AD"
}

variable "ds_managed_ad_vpc_id" {
  type        = string
  description = "VPC ID for the AWS Managed Microsoft AD"
}

variable "management_keypair_name" {
  type        = string
  description = "The name of the keypair to use for the management server"
}

variable "management_subnet_id" {
  type        = string
  description = "A list of subnet IDs to associate with the management server"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "project_name" {
  type        = string
  description = "project name within aws"
}

variable "tags" {
  type        = map(string)
  description = "User defined extra tags to be added to all resources created in the module"
  default     = {}
}

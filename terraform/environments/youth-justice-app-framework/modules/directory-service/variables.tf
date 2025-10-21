variable "project_name" {
  type        = string
  description = "project name within aws"
}

variable "environment" {
  type        = string
  description = "Environment"
}

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

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs."
}

variable "ds_managed_ad_vpc_id" {
  type        = string
  description = "VPC ID for the AWS Managed Microsoft AD"
}

variable "management_keypair_name" {
  type        = string
  description = "The name of the keypair to use for the management server"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "tags" {
  type        = map(string)
  description = "User defined extra tags to be added to all resources created in the module"
  default     = {}
}

variable "ad_management_instance_count" {
  type        = number
  description = "The number of Active Directory Management servers to be created."
  default     = 2
}

variable "desired_number_of_domain_controllers" {
  type        = number
  description = "The number of Doamin Coltrollers to create."
  default     = 2
}

variable "rds_cluster_security_group_id" {
  type        = string
  description = "The Id of the Security Grpoip that enables access to the RDS PostgreSQL Cluster."
}

variable "esb_security_group_id" {
  type        = string
  description = "The security group ID for the ESB server"
}

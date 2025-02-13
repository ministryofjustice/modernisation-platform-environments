variable "application_data" {
  type = map(any)
}

variable "environment" {
  description = "The environment for the application"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "route53_zone_external" {
  description = "The external Route53 zone name"
  type        = string
}

variable "route53_zone_external_id" {
  description = "The external Route53 zone id"
  type        = string
}

variable "shared_ebs_kms_key_id" {
  description = "Shared EBS KMS key ID"
  type        = string
}

variable "shared_vpc_id" {
  description = "Shared VPC ID"
  type        = string
}

variable "bastion_security_group" {
  description = "The security group ID for the bastion host"
  type        = string
}

variable "shared_vpc_cidr" {
  description = "The security group ID for the bastion host"
  type        = string
}

variable "current_account_id" {
  description = "The security group ID for the bastion host"
  type        = string
}

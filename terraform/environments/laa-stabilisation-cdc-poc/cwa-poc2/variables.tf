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

variable "route53_zone_network_services_id" {
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
  description = "Shared VPC CIDR"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "public_subnet_a_id" {
  description = "Public subnet A ID"
  type        = string
}

variable "public_subnet_b_id" {
  description = "Public subnet B ID"
  type        = string
}

variable "public_subnet_c_id" {
  description = "Public subnet C ID"
  type        = string
}

variable "data_subnet_a_id" {
  description = "Data subnet A ID"
  type        = string
}

variable "private_subnet_a_id" {
  description = "Private subnet A ID"
  type        = string
}

variable "management_aws_account" {
  description = "ID of AWS Management account"
  type        = string
}

variable "private_subnet_b_id" {
  description = "Private subnet B ID"
  type        = string
}

variable "private_subnet_c_id" {
  description = "Private subnet C IDs"
  type        = string
}
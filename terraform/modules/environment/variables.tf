variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment_management" {
  description = "The json decoded environment_management secret from modernisation-platform account"
}

variable "business_unit" {
  description = "name of business unit which is also used as part of the VPC name, e.g. hmpps"
  type        = string
}

variable "application_name" {
  description = "name of application, e.g. nomis, oasys etc.."
  type        = string
}

variable "environment" {
  description = "name of environment, e.g. development, test, preproduction, production"
  type        = string
}

variable "subnet_set" {
  description = "modernisation platform subnet set, e.g. general"
  type        = string
  default     = "general"
}

variable "shared_s3_bucket" {
  description = "cross-account shared s3 bucket, e.g. bucket in oasys-test, used by oasys-development and oasys-test"
  type        = string
  default     = ""
}

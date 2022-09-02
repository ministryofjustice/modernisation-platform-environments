variable "always_on" {
  type        = bool
  description = "Set to false if the instance should be shutdown at evenings and weekends"
  default     = false
  nullable    = false
}

variable "ami_name" {
  type        = string
  description = "Name of AMI to be used to launch the ec2 instance"
}

variable "ami_owner" {
  type        = string
  description = "Owner of AMI to be used to launch the ec2 instance"
  default     = "self"
  nullable    = false
}

variable "application_name" {
  type        = string
  description = "The name of the application.  This will be name of the environment in Modernisation Platform"
  default     = "nomis"
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}

variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
  nullable    = false
}

variable "description" {
  type        = string
  description = "VM description, should include information such as what is running on it, etc."
  default     = ""
  nullable    = false
}

variable "extra_ingress_rules" {
  type = list(object({
    description = string
    from_port   = string
    to_port     = string
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "A list of extra ingress rules to be added to the instance security group"
  default     = []
  nullable    = false
}

variable "instance_type" {
  type        = string
  description = "ec2 instance type to use for the instances"
  default     = "t2.large"
  nullable    = false
}

variable "common_security_group_id" {
  type        = string
  description = "Common security group used by all instances"
}

variable "environment" {
  type        = string
  description = "Application environment - i.e. the terraform workspace"
}

variable "instance_profile_policies" {
  type        = list(string)
  description = "A list of managed IAM policy document ARNs to be attached to the base instance profile"
}

variable "key_name" {
  type        = string
  description = "Name of ssh key resource for ec2-user"
}

variable "name" {
  type        = string
  description = "Provide a unique name for the instance"
}

variable "region" {
  type        = string
  description = "The region in which to deploy the instances"
  default     = "eu-west-2"
  nullable    = false
}

variable "subnet_set" {
  type        = string
  description = "Fixed variable to specify subnet-set for RAM shared subnets"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

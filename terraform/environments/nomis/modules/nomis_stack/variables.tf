variable "application_name" {
  type        = string
  description = "Name of application"
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}

variable "bastion_security_group" {
  type        = string
  description = "Security group of Bastion instance that can be used to connect to the database instance"
}

variable "business_unit" {
  type        = string
  description = "Fixed variable to specify business-unit for RAM shared subnets"
}

variable "database_ami_name" {
  type        = string
  description = "name of AMI to be used to launch the database ec2 instance"
}

variable "database_ami_owner" {
  type        = string
  description = "name of AMI to be used to launch the database ec2 instance"
}

variable "database_drive_map" {
  type        = map(any)
  description = "The size of the non-root ebs volumes (GiB) attached to the database instance.  The keys must match the block device names the AMI launches with"
  default = {
    "/dev/sdb" = 100
    "/dev/sdc" = 100
    "/dev/sde" = 100
    "/dev/sdf" = 100
    "/dev/sds" = 16
  }
}

variable "database_instance_type" {
  type        = string
  description = "ec2 instance type to use for the database"
  default     = "r6i.xlarge"
}

variable "environment" {
  type        = string
  description = "application environment"
}

variable "instance_profile_id" {
  type        = string
  description = "IAM instance profile to be attached to the instances"
}

variable "key_name" {
  type        = string
  description = "name of ssh key resource for ec2-user"
}

variable "load_balancer_listener_arn" {
  type        = string
  description = "arn for loadbalancer fronting weblogic server"
}

variable "region" {
  type        = string
  description = ""
}

variable "stack_name" {
  type        = string
  description = "provide a unique name"
  validation {
    condition     = length(var.stack_name) < 6
    error_message = "The stack_name variable must be 5 characters or fewer."
  }
}

variable "subnet_set" {
  type        = string
  description = "Fixed variable to specify subnet-set for RAM shared subnets"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "weblogic_ami_name" {
  type        = string
  description = "name of AMI to be used to launch the weblogic ec2 instance"
}

variable "weblogic_ami_owner" {
  type        = string
  description = "name of AMI to be used to launch the weblogic ec2 instance"
}

variable "weblogic_common_security_group_id" {
  type        = string
  description = "common security group used by all weblogic instances"
}

variable "weblogic_drive_map" {
  type        = map(any)
  description = "the size of the ebs volumes (GiB) attached to the weblogic instance"
  default = {
    "/dev/sdb" = 200
  }
}

variable "weblogic_instance_type" {
  type        = string
  description = "ec2 instance type to use for the database"
  default     = "t2.medium"
}
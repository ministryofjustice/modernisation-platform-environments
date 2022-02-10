variable "application_name" {
  type        = string
  description = "The name of the application.  This will be name of the environment in Modernisation Platform"
  default     = "nomis"
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}

variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
}

variable "database_ami_name" {
  type        = string
  description = "Name of AMI to be used to launch the database ec2 instance"
}

variable "database_ami_owner" {
  type        = string
  description = "Owner of AMI to be used to launch the database ec2 instance"
  default     = "self"
}

variable "database_drive_map" {
  type        = map(any)
  description = "The size of the non-root ebs volumes (GiB) attached to the database instance.  Note this is only relevant for re-sizing those volumes which form part of the AMI block device mappings.  The keys must match the block device names the AMI launches with"
  default = {
    "/dev/sdb" = 100
    "/dev/sdc" = 100
    "/dev/sde" = 100
    "/dev/sdf" = 100
    "/dev/sds" = 16
  }
}

variable "database_extra_ingress_rules" {
  type = list(object({
    description = string
    from_port   = string
    to_port     = string
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "A list of extra ingress rules to be added to the database security group"
  default     = []
}

variable "database_instance_type" {
  type        = string
  description = "ec2 instance type to use for the database"
  default     = "r6i.xlarge"
}

variable "database_common_security_group_id" {
  type        = string
  description = "Common security group used by all database instances"
}

variable "environment" {
  type        = string
  description = "Application environment - i.e. the terraform workspace"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile to be attached to the instances"
}

variable "instance_profile_db_name" {
  type        = string
  description = "IAM instance profile name to be attached to the database instances"
}

variable "instance_profile_weblogic_name" {
  type        = string
  description = "IAM instance profile name to be attached to the weblogic instances"
}

variable "key_name" {
  type        = string
  description = "Name of ssh key resource for ec2-user"
}

variable "load_balancer_listener_arn" {
  type        = string
  description = "arn for loadbalancer fronting weblogic server"
}

variable "region" {
  type        = string
  description = "The AWS region in which to deploy the resources"
  default     = "eu-west-2"
}

variable "stack_name" {
  type        = string
  description = "Provide a unique name for the stack"
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
  description = "Name of AMI to be used to launch the weblogic ec2 instance"
}

variable "weblogic_ami_owner" {
  type        = string
  description = "Owner of AMI to be used to launch the weblogic ec2 instance"
  default     = "self"
}

variable "weblogic_common_security_group_id" {
  type        = string
  description = "Common security group used by all weblogic instances"
}

variable "weblogic_drive_map" {
  type        = map(any)
  description = "The size of the ebs volumes (GiB) attached to the weblogic instance. Note this is only relevant for re-sizing those volumes which form part of the AMI block device mappings. The keys must match the block device names the AMI launches with"
  default     = {}
}

variable "weblogic_instance_type" {
  type        = string
  description = "ec2 instance type to use for the weblogic instance"
  default     = "t2.medium"
}

variable "use_default_creds" {
  type        = string
  description = "Use the default weblogic admin username/password & T1 Nomis db username/password (Parameter Store Variables)"
  default     = "true"
}

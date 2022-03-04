variable "application_name" {
  type        = string
  description = "The name of the application.  This will be name of the environment in Modernisation Platform"
  default     = "nomis"
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}

variable "asm_data_capacity" {
  type = number
  description = "Total capcity of the DATA disk group in GiB"
  default = 200
  validation {
    condition     = var.asm_data_capacity >= 5
    error_message = "The minimum capacity that can be specified for the DATA diskgroup is 5 GiB."
  }
}

variable "asm_data_iops" {
  type = number
  description = "Iops of the DATA disks"
  default = 3000
}

variable "asm_data_throughput" {
  type = number
  description = "Throughout of the DATA disks in MiB/s"
  default = 125
}

variable "asm_flash_capacity" {
  type = number
  description = "Total capcity of the FLASH disk group in GiB"
  default = 100
  validation {
    condition     = var.asm_flash_capacity >= 2
    error_message = "The minimum capacity that can be specified for the FLASH diskgroup is 2 GiB."
  }
}

variable "asm_flash_iops" {
  type = number
  description = "Iops of the FLASH disks"
  default = 3000
}

variable "asm_flash_throughput" {
  type = number
  description = "Throughout of the FLASH disks in MB/s"
  default = 125
}

variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
}

variable "ami_name" {
  type        = string
  description = "Name of AMI to be used to launch the database ec2 instance"
}

variable "ami_owner" {
  type        = string
  description = "Owner of AMI to be used to launch the database ec2 instance"
  default     = "self"
}

# variable "drive_map" {
#   type        = map(any)
#   description = "The size of the non-root ebs volumes (GiB) attached to the database instance.  Note this is only relevant for re-sizing those volumes which form part of the AMI block device mappings.  The keys must match the block device names the AMI launches with"
#   default = {
#     "/dev/sdb" = 100
#     "/dev/sdc" = 100
#     "/dev/sds" = 16
#   }
# }

variable "extra_ingress_rules" {
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

variable "instance_type" {
  type        = string
  description = "ec2 instance type to use for the database"
  default     = "r6i.xlarge"
}

variable "common_security_group_id" {
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

variable "key_name" {
  type        = string
  description = "Name of ssh key resource for ec2-user"
}

variable "region" {
  type        = string
  description = "The AWS region in which to deploy the resources"
  default     = "eu-west-2"
}

variable "name" {
  type        = string
  description = "Provide a unique name for the stack"
  # validation {
  #   condition     = length(var.stack_name) < 6
  #   error_message = "The stack_name variable must be 5 characters or fewer."
  # }
}

variable "subnet_set" {
  type        = string
  description = "Fixed variable to specify subnet-set for RAM shared subnets"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}
variable "ami_name" {
  type        = string
  description = "Name of AMI to be used to launch the database ec2 instance"
}

variable "ami_owner" {
  type        = string
  description = "Owner of AMI to be used to launch the database ec2 instance"
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

variable "asm_data_capacity" {
  type        = number
  description = "Total capacity of the DATA disk group in GiB"
  default     = 5
  nullable    = false
  validation {
    condition     = var.asm_data_capacity >= 5
    error_message = "The minimum capacity that can be specified for the DATA diskgroup is 5 GiB."
  }
}

variable "asm_data_iops" {
  type        = number
  description = "Iops of the DATA disks"
  default     = 3000
  nullable    = false
}

variable "asm_data_throughput" {
  type        = number
  description = "Throughput of the DATA disks in MiB/s"
  default     = 125
  nullable    = false
}

variable "asm_flash_capacity" {
  type        = number
  description = "Total capacity of the FLASH disk group in GiB"
  default     = 2
  nullable    = false
  validation {
    condition     = var.asm_flash_capacity >= 2
    error_message = "The minimum capacity that can be specified for the FLASH diskgroup is 2 GiB."
  }
}

variable "asm_flash_iops" {
  type        = number
  description = "Iops of the FLASH disks"
  default     = 3000
  nullable    = false
}

variable "asm_flash_throughput" {
  type        = number
  description = "Throughput of the FLASH disks in MB/s"
  default     = 125
  nullable    = false
}

variable "availability_zone" {
  type        = string
  description = "The availability zone in which to deploy the infrastructure"
  default     = "eu-west-2a"
  nullable    = false
}

variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
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
  description = "A list of extra ingress rules to be added to the database security group"
  default     = []
  nullable    = false
}

variable "instance_type" {
  type        = string
  description = "ec2 instance type to use for the database"
  default     = "r6i.xlarge"
  nullable    = false
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
  description = "IAM instance profile to be attached to the instance"
}

variable "key_name" {
  type        = string
  description = "Name of ssh key resource for ec2-user"
}

variable "name" {
  type        = string
  description = "Provide a unique name for the instance"
}

variable "oracle_app_disk_size" {
  type        = map(any)
  description = "Capcity of each Oracle application disk, /u01 and /u02"
  default = {
    # "/dev/sdb" = 100
    # "/dev/sdc" = 100
  }
  nullable = false
}

variable "subnet_set" {
  type        = string
  description = "Fixed variable to specify subnet-set for RAM shared subnets"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "termination_protection" {
  type     = bool
  default  = false
  nullable = false
}
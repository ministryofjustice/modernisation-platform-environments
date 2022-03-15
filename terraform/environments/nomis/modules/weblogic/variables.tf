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

variable "asg_max_size" {
  type        = number
  description = "The maximum size of the auto scaling group"
  default     = 1
  nullable    = false
}

variable "asg_min_size" {
  type        = number
  description = "The minimum size of the auto scaling group"
  default     = 1
  nullable    = false
}

variable "asg_desired_capacity" {
  type        = number
  description = "The desired number of instances.  Use for manually scaling, or up the asg_min_size var.  Must be >= asg_min_size and =< asg_max_size."
  default     = null
  nullable    = true
}

variable "asg_warm_pool_min_size" {
  type        = number
  description = "The minimum number of instances that should always be available in the auto scaling group warm pool"
  default     = 0
  nullable    = false
}

# variable "availability_zone" {
#   type        = string
#   description = "The availability zone in which to deploy the infrastructure"
#   default     = "eu-west-2a"
#   nullable    = false
# }

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

# variable "instance_profile_name" {
#   type        = string
#   description = "IAM instance profile to be attached to the instance"
# }

variable "instance_profile_policy_arn" {
  type        = string
  description = "An IAM policy document to be attached to the weblogic instance profile"
}

variable "key_name" {
  type        = string
  description = "Name of ssh key resource for ec2-user"
}

variable "load_balancer_listener_arn" {
  type        = string
  description = "arn for loadbalancer fronting weblogics"
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
  }
  nullable = false
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

variable "termination_protection" {
  type     = bool
  default  = false
  nullable = false
}

variable "use_default_creds" {
  type        = bool
  description = "Use the default weblogic admin username/password & T1 Nomis db username/password (Parameter Store Variables)"
  default     = true
}
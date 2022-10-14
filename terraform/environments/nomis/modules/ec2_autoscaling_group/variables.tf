variable "business_unit" {
  type        = string
  description = "This corresponds to the VPC in which the application resides"
  default     = "hmpps"
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

variable "environment" {
  type        = string
  description = "Application environment - i.e. the terraform workspace"
}

variable "region" {
  type        = string
  description = "Destination AWS Region for the infrastructure"
  default     = "eu-west-2"
}

variable "availability_zone" {
  type        = string
  description = "The availability zone in which to deploy the infrastructure"
  default     = "eu-west-2a"
  nullable    = false
}

variable "subnet_set" {
  type        = string
  description = "Fixed variable to specify subnet-set for RAM shared subnets"
}

variable "subnet_name" {
  type        = string
  description = "Name of subnet within the given subnet-set"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "account_ids_lookup" {
  description = "A map of account names to account ids that can be used for AMI owner"
  default     = {}
}

variable "ansible_repo" {
  type        = string
  description = "Optionally provision the server using this ansible_repo"
  default     = null
}

variable "ansible_repo_basedir" {
  type        = string
  description = "Base directory within ansible_repo where ansible code is located"
  default     = null
}

variable "branch" {
  type        = string
  description = "Git hub branch code is being run from.  For cloning ansible repo"
  default     = ""
}

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

variable "name" {
  type        = string
  description = "Provide a unique name for the auto scale group"
}

variable "instance" {
  description = "EC2 instance settings, see aws_instance documentation"
  type = object({
    disable_api_termination      = bool
    instance_type                = string
    key_name                     = string
    monitoring                   = optional(bool)
    metadata_options_http_tokens = optional(string)
    vpc_security_group_ids       = list(string)
    private_dns_name_options = optional(object({
      enable_resource_name_dns_aaaa_record = optional(bool)
      enable_resource_name_dns_a_record    = optional(bool)
      hostname_type                        = string
    }))
  })
}

variable "user_data" {
  description = "Map of cloud-init config write_file sections for user data"
  type = object({
    args    = optional(map(string))
    scripts = list(string)
    write_files = optional(map(object({
      path        = string
      owner       = string
      permissions = string
    })))
  })
  default = null
}

variable "ebs_volume_config" {
  description = "EC2 volume configurations, where key is a label, e.g. flash, which is assigned to the disk in ebs_volumes.  All disks with same label have the same configuration.  If not specified, use values from the AMI.  If total_size specified, the volume size is this divided by the number of drives with the given label"
  type = map(object({
    iops       = optional(number)
    throughput = optional(number)
    total_size = optional(number)
    type       = optional(string)
  }))
}

variable "ebs_volumes" {
  description = "EC2 volumes, see aws_ebs_volume for documentation.  key=volume name, value=ebs_volume_config key.  label is used as part of the Name tag"
  # Commenting below out as it has unexpected results when used with merge()
  #  type = map(object({
  #    label       = string
  #    snapshot_id = optional(string)
  #    iops        = optional(number)
  #    throughput  = optional(number)
  #    size        = optional(number)
  #    type        = optional(string)
  #  }))
}

variable "iam_resource_names_prefix" {
  type        = string
  description = "Prefix IAM resources with this prefix, e.g. ec2-database"
  default     = "ec2"
}

variable "instance_profile_policies" {
  type        = list(string)
  description = "A list of managed IAM policy document ARNs to be attached to the database instance profile"
}

variable "autoscaling_group" {
  description = "See aws_autoscaling_group documentation"
  type = object({
    desired_capacity          = number
    max_size                  = number
    min_size                  = number
    health_check_grace_period = optional(number)
    health_check_type         = optional(string)
    termination_policies      = optional(list(string))
    target_group_arns         = optional(list(string))
    wait_for_capacity_timeout = optional(number)
    instance_refresh = optional(object({
      strategy               = string
      min_healthy_percentage = number
      instance_warmup        = number
    }))
    warm_pool = optional(object({
      pool_state                  = string
      min_size                    = number
      max_group_prepared_capacity = number
      reuse_on_scale_in           = bool
    }))
  })
}

variable "autoscaling_lifecycle_hooks" {
  description = "See aws_autoscaling_lifecycle_hook documentation.  Key=name"
  type = map(object({
    default_result       = string
    heartbeat_timeout    = number
    lifecycle_transition = string
  }))
}

variable "autoscaling_schedules" {
  description = "See aws_autoscaling_schedule documentation.  Key=name.  Values are taken from equivalent autoscaling_group value if null"
  type = map(object({
    min_size         = optional(number)
    max_size         = optional(number)
    desired_capacity = optional(number)
    recurrence       = string
  }))
}

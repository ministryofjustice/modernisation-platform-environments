variable "application_name" {
  type        = string
  description = "The name of the application.  This will be name of the environment in Modernisation Platform"
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-.]{1,61}[A-Za-z0-9]$", var.application_name))
    error_message = "Invalid name for application supplied in variable app_name."
  }
}

variable "region" {
  type        = string
  description = "Destination AWS Region for the infrastructure"
  default     = "eu-west-2"
}

variable "vpc_id" {
  type        = string
  description = "vpc id which only needs populating if lb_target_groups is set"
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids given to the ASG to set the associated AZs (and therefore redundancy of the ASG instances)"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "account_ids_lookup" {
  description = "A map of account names to account ids that can be used for AMI owner"
  type        = map(any)
  default     = {}
}

variable "ami_name" {
  type        = string
  description = "Name of AMI to be used to launch the ec2 instance"
}

variable "ami_owner" {
  type        = string
  description = "Owner of AMI to be used to launch the ec2 instance"
  default     = "core-shared-services-production"
  nullable    = false
}

variable "name" {
  type        = string
  description = "Provide a unique name for the auto scale group"
}

variable "availability_zone" {
  type        = string
  description = "Optionally associated the ASG with a single availability zone"
  default     = null
}

variable "instance" {
  description = "EC2 launch template / instance settings, see aws_instance documentation"
  type = object({
    disable_api_termination      = bool
    instance_type                = string
    key_name                     = string
    monitoring                   = optional(bool, true)
    metadata_options_http_tokens = optional(string, "required")
    metadata_endpoint_enabled    = optional(string, "enabled")
    vpc_security_group_ids       = list(string)
    private_dns_name_options = optional(object({
      enable_resource_name_dns_aaaa_record = optional(bool)
      enable_resource_name_dns_a_record    = optional(bool)
      hostname_type                        = string
    }))
  })
}

variable "user_data_raw" {
  description = "Base64 encoded user data, script or cloud formation template"
  type        = string
  default     = null
}

variable "user_data_cloud_init" {
  description = "Use this instead of user_data_raw to run multiple scripts using cloud_init"
  type = object({
    args    = optional(map(string))
    scripts = optional(list(string))
    write_files = optional(map(object({
      path        = string
      owner       = string
      permissions = string
    })), {})
  })
  default = null
}

variable "ebs_volumes_copy_all_from_ami" {
  description = "If true, ensure all volumes in AMI are also present in EC2.  If false, only create volumes specified in ebs_volumes var"
  type        = bool
  default     = true
}

variable "ebs_kms_key_id" {
  description = "KMS Key to use for EBS volumes if not explicitly set in ebs_volumes variable.  If null, uses the local account key or the corresponding AMI volume ebs key"
  type        = string
  default     = null
}

variable "ebs_volume_config" {
  description = "EC2 volume configurations, where key is a label, e.g. flash, which is assigned to the disk in ebs_volumes.  All disks with same label have the same configuration.  If not specified, use values from the AMI.  If total_size specified, the volume size is this divided by the number of drives with the given label"
  type = map(object({
    iops       = optional(number)
    throughput = optional(number)
    total_size = optional(number)
    type       = optional(string)
    kms_key_id = optional(string)
  }))
}

variable "ebs_volumes" {
  description = "EC2 volumes, see aws_ebs_volume for documentation.  key=volume name, value=ebs_volume_config key.  label is used as part of the Name tag"
  type = map(object({
    label       = optional(string)
    snapshot_id = optional(string)
    iops        = optional(number)
    throughput  = optional(number)
    size        = optional(number)
    type        = optional(string)
    kms_key_id  = optional(string)
    no_device   = optional(bool)
  }))
}

variable "iam_resource_names_prefix" {
  type        = string
  description = "Prefix IAM resources with this prefix, e.g. ec2-database"
  default     = "ec2"
}

variable "instance_profile_policies" {
  type        = list(string)
  description = "A list of managed IAM policy document ARNs to be attached to the instance profile"
}

variable "autoscaling_group" {
  description = "See aws_autoscaling_group documentation"
  type = object({
    desired_capacity          = number
    max_size                  = number
    min_size                  = number
    health_check_grace_period = optional(number)
    health_check_type         = optional(string)
    force_delete              = optional(bool)
    termination_policies      = optional(list(string))
    target_group_arns         = optional(list(string))
    wait_for_capacity_timeout = optional(number)
    initial_lifecycle_hooks = optional(map(object({
      default_result       = string
      heartbeat_timeout    = number
      lifecycle_transition = string
    })))
    instance_refresh = optional(object({
      strategy               = string
      min_healthy_percentage = number
      instance_warmup        = number
    }))
    warm_pool = optional(object({
      pool_state                  = optional(string)
      min_size                    = optional(number)
      max_group_prepared_capacity = optional(number)
      reuse_on_scale_in           = bool
    }))
  })
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

variable "ssm_parameters_prefix" {
  type        = string
  description = "Optionally prefix ssm parameters with this prefix.  Add a trailing /"
  default     = ""
}

variable "ssm_parameters" {
  description = "A map of SSM parameters to create.  If parameters are manually created, set to {} so IAM role still created"
  type = map(object({
    random = object({
      length  = number
      special = bool
    })
    description = string
  }))
  default = null
}

variable "lb_target_groups" {
  description = "Map of load balancer target groups, where key is the name.  vpc_id needs setting if this is used"
  type = map(object({
    port                 = optional(number)
    protocol             = optional(string)
    target_type          = string
    deregistration_delay = optional(number)
    health_check = optional(object({
      enabled             = optional(bool)
      interval            = optional(number)
      healthy_threshold   = optional(number)
      matcher             = optional(string)
      path                = optional(string)
      port                = optional(number)
      timeout             = optional(number)
      unhealthy_threshold = optional(number)
    }))
    stickiness = optional(object({
      enabled         = optional(bool)
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))
    attachments = optional(list(object({
      target_id         = string
      port              = optional(number)
      availability_zone = optional(string)
    })), [])
  }))
  default = {}
}

variable "cloudwatch_metric_alarms" {
  description = "Map of cloudwatch metric alarms.  The alarm name is set to the autoscaling group name plus the map key."
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_actions       = list(string)
    actions_enabled     = optional(bool, false)
    alarm_description   = optional(string)
    datapoints_to_alarm = optional(number)
    treat_missing_data  = optional(string, "missing")
    dimensions          = optional(map(string), {})
  }))
  default = {}
}


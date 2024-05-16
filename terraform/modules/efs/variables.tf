variable "access_points" {
  description = "map of aws_efs_access_point resources to create where the map key is tags.Name"
  type = map(object({
    posix_user = optional(object({
      gid            = number
      uid            = number
      secondary_gids = optional(list(number))
    }))
    root_directory = optional(object({
      path = string
      creation_info = optional(object({
        owner_gid   = number
        owner_uid   = number
        permissions = string
      }))
    }))
  }))
  default = {}
}

variable "file_system" {
  description = "aws_efs_file_system resource params"
  type = object({
    availability_zone_name          = optional(string)
    kms_key_id                      = string
    performance_mode                = optional(string)
    provisioned_throughput_in_mibps = optional(number)
    throughput_mode                 = optional(string)
    lifecycle_policy = optional(object({
      transition_to_archive               = optional(string)
      transition_to_ia                    = optional(string)
      transition_to_primary_storage_class = optional(string)
      }), {
      transition_to_archive               = null
      transition_to_ia                    = null
      transition_to_primary_storage_class = null
    })
  })
}

variable "mount_targets" {
  description = "map of aws_efs_mount_target resources where map key is not used other than a key to the terraform resource"
  type = map(object({
    subnet_id       = string
    security_groups = list(string)
  }))
  default = {}
}

variable "name" {
  description = "name of file system, added as tags.Name to resources"
  type        = string
}

variable "policy" {
  description = "optionally create aws_efs_file_system_policy resource"
  type = list(object({
    sid       = optional(string, null)
    effect    = string
    actions   = list(string)
    resources = list(string)
    principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = null
}

variable "tags" {
  description = "tags to apply to resources"
  type        = map(string)
  default     = {}
}

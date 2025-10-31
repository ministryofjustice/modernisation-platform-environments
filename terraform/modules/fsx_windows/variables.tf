variable "active_directory_id" {
  description = "The ID for an existing Microsoft Active Directory instance that the file system should join when it's created"
  type        = string
  default     = null
}

variable "aliases" {
  description = "An array DNS alias names that you want to associate with the Amazon FSx file system"
  type        = list(string)
  default     = null
}

variable "automatic_backup_retention_days" {
  description = "The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Defaults to 7. Set to 0 to disable"
  type        = number
  default     = null
}

variable "backup_id" {
  description = "The ID of the source backup to create the filesystem from"
  type        = string
  default     = null
}

variable "daily_automatic_backup_start_time" {
  description = "The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone."
  type        = string
  default     = null
}

variable "deployment_type" {
  description = "Specifies the file system deployment type, valid values are MULTI_AZ_1, SINGLE_AZ_1 and SINGLE_AZ_2. Default value is SINGLE_AZ_1"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "ARN for the KMS Key to encrypt the file system at rest"
  type        = string
  default     = null
}

variable "name" {
  description = "resource name to add to tags.Name"
  type        = string
}

variable "preferred_subnet_id" {
  description = "Specifies the subnet in which you want the preferred file server to be located. Required for when deployment type is MULTI_AZ_1"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "A list of IDs for the security groups that apply to the specified network interfaces created for file system access. These security groups will apply to all network interfaces."
  type        = list(string)
  default     = null
}

variable "skip_final_backup" {
  description = "When enabled, will skip the default final backup taken when the file system is deleted. This configuration must be applied separately before attempting to delete the resource to have the desired behavior. Defaults to false."
  type        = bool
  default     = null
}

variable "self_managed_active_directory" {
  description = "Configuration block that Amazon FSx uses to join the Windows File Server instance to your self-managed (including on-premises) Microsoft Active Directory (AD) directory. Cannot be specified with active_directory_id"
  type = object({
    dns_ips                                = list(string)
    domain_name                            = string
    password_secret_name                   = optional(string) # secret must be json key/pair with username as key
    username                               = string
    file_system_administrators_group       = optional(string) # set if not "Domain Admins"
    organizational_unit_distinguished_name = optional(string)
  })
  default = null
}

variable "storage_capacity" {
  description = "Storage capacity (GiB) of the file system. Minimum of 32 and maximum of 65536. If the storage type is set to HDD the minimum value is 2000. Required when not creating filesystem for a backup."
  type        = number
  default     = null
}

variable "storage_type" {
  description = "Specifies the storage type, Valid values are SSD and HDD. HDD is supported on SINGLE_AZ_2 and MULTI_AZ_1 Windows file system deployment types. Default value is SSD."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "A list of IDs for the subnets that the file system will be accessible from. To specify more than a single subnet set deployment_type to MULTI_AZ_1"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "throughput_capacity" {
  description = "Throughput (megabytes per second) of the file system in power of 2 increments. Minimum of 8 and maximum of 2048."
  type        = number
}

variable "weekly_maintenance_start_time" {
  description = "The preferred start time (in d:HH:MM format) to perform weekly maintenance, in the UTC time zone."
  type        = string
  default     = null
}

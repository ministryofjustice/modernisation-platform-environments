variable "size" {
  description = "The size of the volume in gibibytes (GiB)"
  type        = number
}

variable "type" {
  description = "The type of EBS volume"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "The amount of provisioned IOPS"
  type        = number
  default     = 3000
}

variable "throughput" {
  description = "The amount of throughput (MiB/s) to provision for the volume"
  type        = number
  default     = 125
}

variable "instance_id" {
  description = "The ID of the instance to which to attach the volume"
  type        = string
}

variable "device_name" {
  description = "The device name to expose to the instance (for example, /dev/sdh or xvdh)"
  type        = string
}

variable "availability_zone" {
  description = "The AZ where the volume will exist"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use to encrypt the volume"
  type        = string
  default     = null
}

variable "enable_platform_backups" {
  description = "Enable or disable Mod Platform centralised backups"
  type        = bool
  default     = null
}

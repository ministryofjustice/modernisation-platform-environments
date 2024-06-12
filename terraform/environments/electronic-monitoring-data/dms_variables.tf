# This variable needs to be supplied with the list of database names to be migrated
variable "database_list" {
  type = list(string)
  # cap_dw
  default = [
    "g4s_cap_dw",
    "g4s_emsys_mvp"
  ]
}

variable "dms_replication_instance_class" {
  description = "Name of the replication instance class to be used"
  type        = string
  default     = "dms.c6i.16xlarge"
}

variable "dms_engine_version" {
  description = "Replication Instance Engine Version"
  type        = string
  default     = "3.5.1"
}

variable "dms_availability_zone" {
  description = "Replication Instance AZ"
  type        = string
  default     = "eu-west-2b"
}

variable "dms_allocated_storage_gib" {
  description = "Replication instance storage allocation - GiB"
  type        = number
  default     = 100
}

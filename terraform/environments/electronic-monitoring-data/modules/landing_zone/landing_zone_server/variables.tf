variable "data_store_bucket" {
  description = "The bucket landed data is moved to"
}

variable "eip_id" {
    description = "The elastic IP address"
}

variable "kms_key" {
  description = "The KMS key for server cloudlog encryption"
}

variable "landing_bucket" {
  description = "The landing bucket that data is placed in"
}

variable "local_tags" {
  description = "The predefined local.tags"
}

variable "subnet_ids" {
  description = "The subnet ids used for the SFTP server"
  type        = list(string)
}

variable "supplier" {
  description = "The name of the supplier the SFTP server is for"
  type        = string
}

variable "user_accounts" {
  description = "The names of the user accounts to create"
  type = list(object({
    name       = string
    ssh_keys   = list(string)
    cidr_ipv4s = list(string)
    cidr_ipv6s = list(string)
  }))
  default = []
}

variable "vpc_id" {
  description = "The vpc used for the SFTP server"
}

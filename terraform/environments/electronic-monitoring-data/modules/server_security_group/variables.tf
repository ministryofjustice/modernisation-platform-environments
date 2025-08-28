variable "cidr_ipv4s" {
  description = "The allowed IPv4 addresses that can access the SFTP server"
  type        = list(string)
  default     = []
}

variable "cidr_ipv6s" {
  description = "The allowed IPv6 addresses that can access the SFTP server"
  type        = list(string)
  default     = []
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
}

variable "supplier" {
  description = "The name of the supplier the SFTP server is for"
  type        = string
}

variable "user_name" {
  description = "The user name for the SFTP server account"
  type        = string
}

variable "vpc_id" {
  description = "The vpc used for the SFTP server"
  type        = string
}

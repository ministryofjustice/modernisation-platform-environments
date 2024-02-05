variable "supplier" {
  description = "The name of the supplier the SFTP server is for"
  type        = string
}

variable "user_accounts"{
  description = "The names of the user accounts to create"
  type        = list(any)
  # type        = list(map(object({
  #   name       = string
  #   ssh_keys   = list(string)
  #   cidr_ipv4s = list(string)
  #   cidr_ipv6s = list(string)
  # })))
  default     = []
}

variable "data_store_bucket" {
  description = "The bucket landed data is moved to"
}

variable "account_id" {
    description = "The account id"
}

variable "vpc_id" {
    description = "The vpc used for the SFTP server"
}

variable "subnet_ids" {
    description = "The subnet ids used for the SFTP server"
    type        = list(string)
}

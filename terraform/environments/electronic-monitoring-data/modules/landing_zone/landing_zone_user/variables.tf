variable "landing_bucket" {
  description = "The landing bucket that data is placed in"
}

variable "local_tags" {
  description = "The predefined local.tags"
}

variable "ssh_keys" {
  description = "The public ssh key for the SFTP server"
  type        = list(string)
}

variable "supplier" {
  description = "The name of the supplier the SFTP server is for"
  type        = string
}

variable "transfer_server" {
  description = "The SFTP server"
}

variable "user_name" {
  description = "The user name for the SFTP server account"
  type        = string
}

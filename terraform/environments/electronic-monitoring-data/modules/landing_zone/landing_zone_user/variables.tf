variable "landing_bucket" {
  description = "The landing bucket that data is placed in"
}

variable "ssh_keys" {
  description = "The public ssh key for the SFTP server"
  type        = list(string)
}

variable "transfer_server" {
  description = "The SFTP server"
}

variable "user_name" {
  description = "The user name for the SFTP server account"
  type        = string
}

variable "landing_bucket" {
  description = "The landing bucket that data is placed in"
  type = object({
    arn = string
    id  = string
  })

}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
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
  type = object({
    id = string
  })
}

variable "user_name" {
  description = "The user name for the SFTP server account"
  type        = string
}

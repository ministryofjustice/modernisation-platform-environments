variable "server_id" {
  description = "Transfer Family server ID"
  type        = string
}

variable "user_name" {
  description = "Username for the SFTP user"
  type        = string
}

variable "ssh_key_body" {
  description = "SSH public key string"
  type        = string
}

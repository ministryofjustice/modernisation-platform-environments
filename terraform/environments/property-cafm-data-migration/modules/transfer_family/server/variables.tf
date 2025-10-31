variable "name" {
  description = "Name tag for the SFTP server"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. development, preprod, prod)"
  type        = string
}

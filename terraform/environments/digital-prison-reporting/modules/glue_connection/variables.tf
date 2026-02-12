variable "name" {
  description = "The Glue Connection name."
}

variable "connection_url" {
  description = "The Glue Connection JDBC URL."
}

variable "password" {
  description = "The Glue Connection JDBC URL'S Password."
}

variable "username" {
  description = "The Glue Connection JDBC URL'S Username."
}

variable "security_groups" {
  description = "The list of security groups."
  type        = list(string)
}

variable "subnet" {
  description = "The subnet ID."
}

variable "availability_zone" {
  description = "The availability zone of subnet."
}

variable "description" {}

variable "create_connection" {
  default = false
}
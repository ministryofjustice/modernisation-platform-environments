variable "data_store_bucket" {
  description = "The bucket landed data is moved to"
}

variable "supplier" {
  description = "The name of the supplier the SFTP server is for"
  type        = string
}

variable "supplier" {
  description = "The name of the supplier the SFTP server is for"
  type        = string
}

variable "give_access" {
  description = "When true, access is given to supplier"
  type        = bool  
}

variable "supplier_shh_key" {
  description = "The public ssh key for the supplier the SFTP server is for"
  type        = string
}

variable "supplier_cidr_ipv4s" {
  description = "The allowed IP addresses for the supplier that can access the SFTP server"
  type        = list(string)
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

variable "kms_key_id" {
  description = "The AWS KMS key"
}

variable "give_dev_access" {
  description = "When true, developer access is given to sftp server"
  type        = bool  
}

variable "dev_ssh_keys" {
  description = "The public ssh key for devs for the SFTP server"
  type        = list(string)
}

variable "dev_cidr_ipv4s" {
  description = "The allowed IP addresses for developers that can access the SFTP server"
  type        = list(string)
}

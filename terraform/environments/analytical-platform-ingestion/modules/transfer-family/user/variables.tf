variable "name" {
  type = string
}

variable "ssh_key" {
  type = string
}

# variable "cidr_blocks" {
#   type = list(string)
# }

# cidr_blocks as set; deduplicates at user level
variable "cidr_blocks" {
  type = set(string)
}

variable "transfer_server" {
  type = string
}

variable "isolated_vpc_id" {
  type = string
}

# original
# variable "transfer_server_security_group" {
#   type = string
# }

variable "landing_bucket" {
  type = string
}

variable "landing_bucket_kms_key" {
  type = string
}

variable "supplier_data_kms_key" {
  type = string
}

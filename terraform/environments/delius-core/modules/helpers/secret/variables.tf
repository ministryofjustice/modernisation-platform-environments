variable "name" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "allowed_account_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type = any
}

variable "generate_random_password" {
  type    = bool
  default = false
}


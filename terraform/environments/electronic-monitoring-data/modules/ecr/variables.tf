variable "ecr_name" {
  description = "The name of the registry"
  type        = any
  default     = null
}

variable "image_mutability" {
  description = "The image mutability"
  type        = string
  default     = "IMMUTABLE"
}

variable "encrypt_type" {
  description = "Type of encryption"
  type        = string
  default     = "KMS"
}

variable "tags" {
  description = "The maps for tagging"
  type        = map(string)
  default     = {}
}
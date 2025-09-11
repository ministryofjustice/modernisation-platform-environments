variable "region" {
  description = "Stores the region"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  description = "Stores the CIDR in use"
  type        = string
  default     = "10.26.24.0/21"
}

variable "availability_zones" {
  description = "Lists the zone that can be used"
  type        = string
  default     = "eu-west-2"
}

variable "bucket_name" {
  description = "The bucket that will be used"
  type        = string
  default     = "t4-environment-bucket-12345678"
}

variable "region" {
  description = "Stores the region"
  type        = string
  default     = "eu-west-2"
}

variable "vip_cidr" {
  description = "Stores the CIDR in use"
  type        = string
  default     = "10.26.24.0/21"
}

variable "availability_zones" {
  description = "Lists the zone that can be used"
  type        = string
  default     = "eu-west-2"
}


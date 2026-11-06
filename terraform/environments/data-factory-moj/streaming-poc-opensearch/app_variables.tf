variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_3.5"
}

variable "instance_type" {
  type    = string
  default = "m6g.large.search"
}

variable "instance_count" {
  type    = number
  default = 2
}


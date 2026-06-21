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

variable "opensearch_role_mappings" {
  description = "Map of OpenSearch role name to backend IAM role ARNs and/or internal users."
  type = map(object({
    backend_roles = optional(list(string), [])
    users         = optional(list(string), [])
  }))
  default = {}
}

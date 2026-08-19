variable "application_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Two subnet IDs in different AZs for AD Connector and WorkSpaces."
}

variable "domain_name" {
  type = string
}

variable "ad_connector_size" {
  type    = string
  default = "Small"
}

variable "ad_connector_username" {
  type = string
}

variable "ad_connector_password" {
  type      = string
  sensitive = true
}

variable "dns_ips" {
  type = list(string)
}

variable "default_ou" {
  type = string
}

variable "bundle_id" {
  type        = string
  description = "Custom WorkSpaces bundle ID. Leave empty to skip workspace provisioning."
  default     = ""
}

variable "running_mode" {
  type    = string
  default = "AUTO_STOP"
}

variable "auto_stop_timeout" {
  type    = number
  default = 60
}

variable "ip_group_allowed_cidrs" {
  type = list(object({
    source      = string
    description = string
  }))
  default = []
}

variable "workspace_users" {
  type        = map(string)
  description = "Map of user keys to AD usernames for WorkSpaces provisioning."
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "security_group_name" {
  type        = string
  description = "Override the security group name. Defaults to {application_name}-{environment}-workspaces-sg."
  default     = ""
}

variable "ip_group_name" {
  type        = string
  description = "Override the IP access control group name."
  default     = ""
}

variable "ip_group_description" {
  type    = string
  default = ""
}

variable "create_service_role" {
  type        = bool
  default     = true
  description = "Create the workspaces_DefaultRole. Set to false if it already exists in the account."
}

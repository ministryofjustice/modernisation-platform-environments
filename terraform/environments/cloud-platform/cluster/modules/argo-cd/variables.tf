###############################################################################
# Argo CD Module — Variables
#
# Enables the EKS Capability for Argo CD on the hub cluster (ADR-002).
# Uses aws_eks_capability resource (provider >= 6.46.0).
###############################################################################

variable "cluster_name" {
  description = "Name of the hub EKS cluster where Argo CD Capability is enabled"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the hub EKS cluster"
  type        = string
}

#------------------------------------------------------------------------------
# Identity Center (required for Argo CD authentication)
#------------------------------------------------------------------------------
variable "idc_instance_arn" {
  description = "ARN of the AWS IAM Identity Center instance"
  type        = string
}

variable "idc_region" {
  description = "Region of the IAM Identity Center instance (defaults to provider region)"
  type        = string
  default     = ""
}

variable "rbac_role_mappings" {
  description = <<-EOT
    Map of ArgoCD RBAC roles to Identity Center identities.
    Keys are role names: ADMIN, EDITOR, VIEWER (case-sensitive).
    Values are lists of identity objects with id (group/user ID) and type (SSO_GROUP or SSO_USER).

    Example:
      {
        ADMIN  = [{ id = "group-id-1", type = "SSO_GROUP" }]
        EDITOR = [{ id = "group-id-2", type = "SSO_GROUP" }, { id = "group-id-3", type = "SSO_GROUP" }]
        VIEWER = [{ id = "group-id-4", type = "SSO_GROUP" }]
      }
  EOT
  type = map(list(object({
    id   = string
    type = string # SSO_USER or SSO_GROUP
  })))
  default = {}

  validation {
    condition = alltrue([
      for role in keys(var.rbac_role_mappings) : contains(["ADMIN", "EDITOR", "VIEWER"], role)
    ])
    error_message = "RBAC role keys must be one of: ADMIN, EDITOR, VIEWER (case-sensitive)."
  }
}

#------------------------------------------------------------------------------
# CodeConnections (GitHub Access)
#------------------------------------------------------------------------------
variable "codeconnection_arn" {
  description = "AWS CodeConnections ARN for GitHub repository access (empty to skip)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Destroy Cleanup
#------------------------------------------------------------------------------
variable "enable_destroy_cleanup" {
  description = "Enable pre-destroy cleanup of ArgoCD resources. Set to true for dev clusters that are routinely destroyed; false for production hubs."
  type        = bool
  default     = true
}

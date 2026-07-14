variable "created_by" {
  type        = string
  default     = null
  description = "User or system identifier to stamp into the immutable created-by tag (set via TF_VAR_created_by on first apply)."

  validation {
    condition     = var.created_by == null || length(trimspace(var.created_by)) > 0
    error_message = "created_by must not be empty."
  }
}

#------------------------------------------------------------------------------
# Argo CD Hub Cluster Configuration (ADR-002)
#------------------------------------------------------------------------------
variable "enable_argocd" {
  type        = bool
  default     = false
  description = "Enable the EKS Capability for Argo CD on this cluster (hub cluster role)."
}

variable "argocd_idc_instance_arn" {
  type        = string
  default     = "" # Set to your org's IAM Identity Center instance ARN
  description = "ARN of the AWS IAM Identity Center instance for Argo CD authentication. Required when enable_argocd is true."
}

variable "argocd_idc_region" {
  type        = string
  default     = "eu-west-2"
  description = "Region of the IAM Identity Center instance."
}

variable "argocd_admin_group_id" {
  type        = string
  default     = ""
  description = "IAM Identity Center Group ID for the platform-engineer-admin SSO group. Grants ADMIN role in Argo CD. For BU team access (EDITOR/VIEWER), add groups to argocd_rbac_role_mappings."
}

variable "argocd_rbac_role_mappings" {
  type = map(list(object({
    id   = string
    type = string
  })))
  default     = {}
  description = <<-EOT
    Additional RBAC role mappings for ArgoCD beyond the admin group.
    Keys: ADMIN, EDITOR, VIEWER. Values: list of IDC identity objects.
    Used to grant BU teams access to the ArgoCD UI.
    Example: { VIEWER = [{ id = "hmpps-sre-group-id", type = "SSO_GROUP" }] }
  EOT
}

variable "argocd_codeconnection_arn" {
  type        = string
  default     = ""
  description = "AWS CodeConnections ARN for GitHub repository access from Argo CD."
}

#------------------------------------------------------------------------------
# Argo CD Spoke Registration (ADR-002 — Spoke-Driven Model)
#------------------------------------------------------------------------------
variable "argocd_hub_spoke_access_role_arn" {
  type        = string
  default     = ""
  description = "ARN of the hub cluster's ArgoCD spoke-access IAM role. When set, registers this cluster as a spoke by granting the hub role an EKS Access Entry with AmazonEKSClusterAdminPolicy. Cross-account: the role is in the hub account."
}

variable "argocd_register_as_spoke" {
  type        = bool
  default     = false
  description = "Register this cluster as an ArgoCD spoke. Uses the hub configuration in locals to construct the spoke-access role ARN. Mutually exclusive with enable_argocd (a cluster is either a hub or a spoke, not both)."
}

resource "null_resource" "created_by_tag" {
  triggers = {
    # Persist the initial creator value in state; ignore future tf var changes.
    created_by = coalesce(var.created_by, "__unset__")
  }

  lifecycle {
    ignore_changes = [triggers["created_by"]]
  }
}

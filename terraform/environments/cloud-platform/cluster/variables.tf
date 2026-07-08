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

variable "argocd_rbac_admin_identities" {
  type = list(object({
    id   = string
    type = string
  }))
  default     = []
  description = "List of Identity Center identities (SSO_USER or SSO_GROUP) to grant ADMIN role in Argo CD."
}

variable "argocd_codeconnection_arn" {
  type        = string
  default     = ""
  description = "AWS CodeConnections ARN for GitHub repository access from Argo CD."
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

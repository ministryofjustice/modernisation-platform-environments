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

variable "rbac_admin_identities" {
  description = "List of Identity Center identities to grant ADMIN role in Argo CD"
  type = list(object({
    id   = string
    type = string # SSO_USER or SSO_GROUP
  }))
  default = []
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

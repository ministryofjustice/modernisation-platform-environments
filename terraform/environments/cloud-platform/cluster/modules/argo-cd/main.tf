###############################################################################
# Argo CD Module — EKS Capability for Argo CD
#
# Enables the AWS-managed Argo CD on the hub cluster (ADR-002).
# Key characteristics:
# - Runs in AWS-managed infrastructure (not on worker nodes)
# - Cross-account private cluster access via EKS ARN + Access Entries
# - No VPC peering or TGW required for GitOps traffic
# - IAM Identity Center authentication
# - CodeConnections for GitHub repository access
# - One Argo CD Capability per cluster (EKS hard limit)
#
# Requires AWS provider >= 6.46.0 for aws_eks_capability resource.
###############################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.10"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

#------------------------------------------------------------------------------
# IAM Role for Argo CD Capability
#
# Trust policy: EKS Capabilities service principal
#------------------------------------------------------------------------------
resource "aws_iam_role" "argocd_capability" {
  name        = "${var.cluster_name}-argocd-capability"
  description = "IAM role for EKS Argo CD Capability on ${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-argocd-capability"
  })
}

#------------------------------------------------------------------------------
# IAM Propagation Delay
#
# EKS validates the trust policy when creating the capability. IAM role
# propagation is eventually consistent (~10s). Without this delay, the
# CreateCapability API call can fail with "trust policy is invalid" on
# fresh deployments where the role was just created.
#------------------------------------------------------------------------------
resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role.argocd_capability]
  create_duration = "15s"
}

#------------------------------------------------------------------------------
# EKS Capability for Argo CD
#
# Uses aws_eks_capability resource (provider >= 6.46.0).
# Provisions the AWS-managed Argo CD instance on the hub cluster.
#------------------------------------------------------------------------------
resource "aws_eks_capability" "argocd" {
  cluster_name              = var.cluster_name
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  depends_on = [time_sleep.iam_propagation]

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = var.idc_instance_arn
        idc_region       = var.idc_region
      }

      namespace = "argocd"

      dynamic "rbac_role_mapping" {
        for_each = var.rbac_admin_identities
        content {
          role = "ADMIN"
          identity {
            id   = rbac_role_mapping.value.id
            type = rbac_role_mapping.value.type
          }
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-argocd"
  })

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

#------------------------------------------------------------------------------
# Argo CD Cross-Account Spoke Access Role
#
# This role is assumed by the Argo CD Capability to deploy to spoke clusters.
# Each spoke cluster registers this role as an EKS Access Entry with
# AmazonEKSClusterAdminPolicy for GitOps deployments.
#------------------------------------------------------------------------------
resource "aws_iam_role" "argocd_spoke_access" {
  name        = "${var.cluster_name}-argocd-spoke-access"
  description = "Allows Argo CD Capability to access spoke EKS clusters"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnEquals = {
            "aws:SourceArn" = var.cluster_arn
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-argocd-spoke-access"
    Purpose = "cross-account-gitops"
  })
}

#------------------------------------------------------------------------------
# CodeConnections for GitHub repository access
#------------------------------------------------------------------------------
resource "aws_iam_role_policy" "argocd_codeconnection" {
  count = var.codeconnection_arn != "" ? 1 : 0

  name = "codeconnection-access"
  role = aws_iam_role.argocd_spoke_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UseCodeConnection"
        Effect = "Allow"
        Action = [
          "codeconnections:UseConnection",
          "codeconnections:GetConnection",
        ]
        Resource = var.codeconnection_arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Register Argo CD IAM role as Access Entry on the hub cluster
#------------------------------------------------------------------------------
resource "aws_eks_access_entry" "argocd_hub" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.argocd_spoke_access.arn
  type          = "STANDARD"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-argocd-hub-access"
  })
}

resource "aws_eks_access_policy_association" "argocd_hub" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.argocd_spoke_access.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.argocd_hub]
}

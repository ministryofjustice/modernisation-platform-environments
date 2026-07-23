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
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Flatten the role -> identities map into a flat list for the dynamic block
  # Input:  { ADMIN = [{id, type}], EDITOR = [{id, type}] }
  # Output: [{role, id, type}, {role, id, type}, ...]
  flattened_rbac_mappings = flatten([
    for role, identities in var.rbac_role_mappings : [
      for identity in identities : {
        role = role
        id   = identity.id
        type = identity.type
      }
    ]
  ])
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
#
# delete_propagation_policy: AWS only supports RETAIN (keeps K8s resources
# after capability deletion). For dev clusters that are routinely destroyed,
# a null_resource provisioner below handles pre-destroy cleanup of the argocd
# namespace to prevent the cluster deletion from hanging.
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
        for_each = local.flattened_rbac_mappings
        content {
          role = rbac_role_mapping.value.role
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
# Pre-Destroy Cleanup for Development Clusters
#
# When the cluster is destroyed, the ArgoCD capability must be deleted first,
# and K8s resources in the argocd namespace cleaned up. Without this, the
# RETAIN policy leaves finalizer-bearing resources that block cluster deletion.
#
# This provisioner:
# 1. Deletes all ArgoCD Applications (to stop sync loops)
# 2. Deletes the ArgoCD capability via AWS API
# 3. Force-removes finalizers from the argocd namespace
# 4. Deletes the argocd namespace
#
# Only runs on `terraform destroy`. For production clusters where the
# capability should outlive individual Terraform runs, set
# enable_destroy_cleanup = false.
#------------------------------------------------------------------------------
resource "null_resource" "argocd_destroy_cleanup" {
  count = var.enable_destroy_cleanup ? 1 : 0

  triggers = {
    cluster_name    = var.cluster_name
    capability_name = aws_eks_capability.argocd.capability_name
    region          = data.aws_region.current.region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set +e
      echo "=== ArgoCD Pre-Destroy Cleanup ==="

      CLUSTER="${self.triggers.cluster_name}"
      REGION="${self.triggers.region}"

      # Step 1: Update kubeconfig for kubectl access
      aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION" --kubeconfig /tmp/kubeconfig-destroy 2>/dev/null
      export KUBECONFIG=/tmp/kubeconfig-destroy

      # Step 2: Delete all ArgoCD Applications to stop sync loops
      echo "Deleting ArgoCD Applications..."
      kubectl delete applications --all -n argocd --timeout=60s 2>/dev/null || true

      # Step 3: Delete all ApplicationSets
      echo "Deleting ArgoCD ApplicationSets..."
      kubectl delete applicationsets --all -n argocd --timeout=60s 2>/dev/null || true

      # Step 4: Delete the ArgoCD capability via AWS API
      echo "Deleting ArgoCD EKS Capability..."
      aws eks delete-capability \
        --cluster-name "$CLUSTER" \
        --capability-name argocd \
        --region "$REGION" 2>/dev/null || true

      # Step 5: Wait for capability deletion
      echo "Waiting for capability deletion..."
      for i in $(seq 1 30); do
        STATUS=$(aws eks describe-capability \
          --cluster-name "$CLUSTER" \
          --capability-name argocd \
          --region "$REGION" \
          --query 'capability.status' --output text 2>/dev/null)
        if [ "$STATUS" = "" ] || [ "$STATUS" = "None" ]; then
          echo "Capability deleted."
          break
        fi
        echo "  Status: $STATUS (attempt $i/30)"
        sleep 10
      done

      # Step 6: Remove finalizers from argocd namespace resources
      echo "Removing finalizers from argocd namespace resources..."
      for resource in $(kubectl api-resources --namespaced -o name 2>/dev/null); do
        kubectl get "$resource" -n argocd -o name 2>/dev/null | while read -r item; do
          kubectl patch "$item" -n argocd --type=merge -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
        done
      done

      # Step 7: Force-delete the argocd namespace
      echo "Deleting argocd namespace..."
      kubectl delete namespace argocd --timeout=60s 2>/dev/null || true

      # Step 8: If namespace is stuck terminating, patch it
      kubectl get namespace argocd 2>/dev/null && \
        kubectl patch namespace argocd --type=merge -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true

      # Cleanup
      rm -f /tmp/kubeconfig-destroy
      echo "=== ArgoCD Pre-Destroy Cleanup Complete ==="
    EOT
  }

  depends_on = [aws_eks_capability.argocd]
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

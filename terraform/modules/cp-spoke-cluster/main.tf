###############################################################################
# CP Spoke Cluster Module
#
# Creates an EKS Auto Mode cluster for a spoke environment.
# Auto Mode handles compute provisioning, CNI, CoreDNS, kube-proxy, and
# EBS CSI driver. This module only configures access entries and addons
# that Auto Mode does not manage.
###############################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Endpoint access
  endpoint_private_access = true
  endpoint_public_access  = var.endpoint_public_access

  # Control plane logging
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  # EKS Auto Mode
  compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  # API authentication mode
  authentication_mode = "API"

  # Bootstrap admin
  enable_cluster_creator_admin_permissions = true

  # Access Entries
  access_entries = var.access_entries

  # Addons not managed by Auto Mode
  addons = {
    eks-pod-identity-agent = {
      before_compute = true
    }
    aws-guardduty-agent = {}
  }

  tags = var.tags
}

###############################################################################
# Secrets Store CSI Driver — EKS Managed Addon (US-005c)
#
# Mounts secrets from AWS Secrets Manager as pod volumes.
# Uses Pod Identity for authentication. AWS manages the driver and provider
# as a single addon — no Helm charts required.
###############################################################################

resource "aws_eks_addon" "secrets_store_csi" {
  cluster_name = local.cluster_name
  addon_name   = "aws-secrets-store-csi-driver-provider"

  tags = local.tags
}

###############################################################################
# Secrets Store CSI Driver + AWS Provider (US-005c)
#
# Mounts secrets from AWS Secrets Manager as pod volumes.
# The AWS provider DaemonSet fetches secrets using Pod Identity.
#
# NOTE: Requires Gatekeeper module update before deploy — see gatekeeper.tf TODO.
###############################################################################

resource "helm_release" "secrets_store_csi" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.7"
  namespace  = "kube-system"

  set = [
    { name = "syncSecret.enabled", value = "true" },
    { name = "enableSecretRotation", value = "true" },
    { name = "rotationPollInterval", value = "3600s" },
  ]
}

resource "helm_release" "secrets_store_aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.3.11"
  namespace  = "kube-system"

  depends_on = [helm_release.secrets_store_csi]
}

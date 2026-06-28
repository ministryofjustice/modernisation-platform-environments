crds:
  # This option decides if the CRDs should be installed
  # as part of the Helm installation.
  enabled: true

  # This option makes it so that the "helm.sh/resource-policy": keep
  # annotation is added to the CRD. This will prevent Helm from uninstalling
  # the CRD when the Helm release is uninstalled.
  # WARNING: when the CRDs are removed, all cert-manager custom resources
  # (Certificates, Issuers, ...) will be removed too by the garbage collector.
  keep: true

serviceAccount:
  create: true

replicaCount: ${certman_replicas}

webhook:
  replicaCount: ${webhook_replicas}

cainjector:
  replicaCount: ${cainjector_replicas}

config:
  enableGatewayAPI: true
  enableGatewayAPIListenerSet: true
  featureGates:
    ListenerSets: true  
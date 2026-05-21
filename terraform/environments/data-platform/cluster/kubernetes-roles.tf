resource "kubernetes_cluster_role_v1" "headlamp" {
  metadata {
    name = "headlamp-readonly"
  }

  rule {
    api_groups = [""]
    resources = [
      "pods", "pods/log", "services", "endpoints", "namespaces", "nodes",
      "configmaps", "events", "persistentvolumeclaims", "persistentvolumes",
      "serviceaccounts", "limitranges", "resourcequotas"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "clusterroles", "rolebindings", "clusterrolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources  = ["httproutes", "gatewayclasses", "gateways"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["karpenter.sh"]
    resources  = ["nodepools", "nodeclaims"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["karpenter.k8s.aws"]
    resources  = ["ec2nodeclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificates", "certificaterequests", "issuers", "clusterissuers"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["keda.sh"]
    resources  = ["scaledobjects", "scaledjobs"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role" "headlamp" {
  metadata {
    name = "headlamp-readonly"
  }

  rule {
    api_groups = [""]
    resources = [
      "pods",
      "pods/log",
      "services",
      "endpoints",
      "namespaces",
      "nodes",
      "configmaps",
      "events",
      "persistentvolumeclaims",
      "persistentvolumes",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "statefulsets",
      "daemonsets",
      "replicasets",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "jobs",
      "cronjobs",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources = [
      "httproutes",
      "gatewayclasses",
      "gateways",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["karpenter.sh"]
    resources = [
      "nodepools",
      "nodeclaims",
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources = [
      "pods",
      "nodes",
    ]
    verbs = ["get", "list", "watch"]
  }
}

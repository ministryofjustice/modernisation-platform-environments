resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

resource "kubernetes_namespace" "aws_observability" {
  metadata {
    name = "aws-observability"
  }
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "kubecost" {
  metadata {
    name = "kubecost"
  }
}

resource "kubernetes_namespace" "actions_runners" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name = "actions-runners"
    labels = {
      "pod-security.kubernetes.io/enforce"         = "baseline"
      "pod-security.kubernetes.io/enforce-version" = "v${local.environment_configuration.eks_cluster_version}"
    }
  }
}

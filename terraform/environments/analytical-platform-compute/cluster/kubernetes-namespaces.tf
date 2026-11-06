resource "kubernetes_namespace_v1" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

resource "kubernetes_namespace_v1" "aws_observability" {
  metadata {
    name = "aws-observability"
  }
}

resource "kubernetes_namespace_v1" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }
}

resource "kubernetes_namespace_v1" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_namespace_v1" "keda" {
  metadata {
    name = "keda"
  }
}

resource "kubernetes_namespace_v1" "velero" {
  metadata {
    name = "velero"
  }
}

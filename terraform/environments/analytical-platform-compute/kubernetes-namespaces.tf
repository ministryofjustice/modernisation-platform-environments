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

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
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

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_namespace" "keda" {
  metadata {
    name = "keda"
  }
}

resource "kubernetes_namespace" "actions_runners" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name = "actions-runners"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "baseline"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "actions-runners"
    }
  }
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "baseline" # This was restricted, but the current pod specification doesn't set the right metadata
      "compute.analytical-platform.service.justice.gov.uk/workload" = "airflow"
    }
  }
}

resource "kubernetes_namespace" "mlflow" {
  metadata {
    name = "mlflow"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "mlflow"
    }
  }
}

resource "kubernetes_namespace" "ui" {
  metadata {
    name = "ui"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "ui"
    }
  }
}

resource "kubernetes_namespace" "mwaa" {
  metadata {
    name = "mwaa"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "airflow"
    }
  }
}

resource "kubernetes_namespace" "dashboard_service" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  metadata {
    name = "dashboard-service"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "dashboard-service"
    }
  }
}

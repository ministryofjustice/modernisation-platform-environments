// Derived from https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-eks-example.html#eksctl-role
resource "kubernetes_role" "airflow_execution" {
  metadata {
    name      = "airflow-execution"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  rule {
    api_groups = [
      "",
      "apps",
      "batch",
      "extensions",
    ]
    resources = [
      "jobs",
      "pods",
      "pods/attach",
      "pods/exec",
      "pods/log",
      "pods/portforward",
      "secrets",
      "services"
    ]
    verbs = [
      "create",
      "delete",
      "describe",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
}

resource "kubernetes_role" "airflow_serviceaccount_management" {
  metadata {
    name      = "airflow-serviceaccount-management"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs = [
      "create",
      "delete",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
}

resource "kubernetes_role" "mwaa_execution" {
  metadata {
    name      = "mwaa-execution"
    namespace = kubernetes_namespace.mwaa.metadata[0].name
  }
  rule {
    api_groups = [
      "",
      "apps",
      "batch",
      "extensions",
    ]
    resources = [
      "jobs",
      "pods",
      "pods/attach",
      "pods/exec",
      "pods/log",
      "pods/portforward",
      "secrets",
      "services"
    ]
    verbs = [
      "create",
      "delete",
      "describe",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
}

resource "kubernetes_role" "mwaa_serviceaccount_management" {
  metadata {
    name      = "mwaa-serviceaccount-management"
    namespace = kubernetes_namespace.mwaa.metadata[0].name
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs = [
      "create",
      "delete",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
}

resource "kubernetes_role" "mwaa_external_secrets" {
  metadata {
    name      = "mwaa-external-secrets"
    namespace = kubernetes_namespace.mwaa.metadata[0].name

  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs = [
      "create",
      "delete",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
  rule {
    api_groups = ["external-secrets.io"]
    resources  = ["externalsecrets"]
    verbs = [
      "create",
      "delete",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
}

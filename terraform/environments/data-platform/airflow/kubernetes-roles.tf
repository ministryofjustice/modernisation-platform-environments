// Derived from https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-eks-example.html#eksctl-role
resource "kubernetes_role_v1" "airflow_execution" {
  metadata {
    name      = "airflow-execution"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
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

resource "kubernetes_role_v1" "airflow_serviceaccount_management" {
  metadata {
    name      = "airflow-serviceaccount-management"
    namespace = kubernetes_namespace_v1.airflow.metadata[0].name
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

resource "kubernetes_role_v1" "mwaa_execution" {
  metadata {
    name      = "mwaa-execution"
    namespace = kubernetes_namespace_v1.mwaa.metadata[0].name
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
  # Needed by cncf-kubernetes 10.x: KubernetesPodOperator reads pod events while waiting
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_v1" "mwaa_serviceaccount_management" {
  metadata {
    name      = "mwaa-serviceaccount-management"
    namespace = kubernetes_namespace_v1.mwaa.metadata[0].name
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

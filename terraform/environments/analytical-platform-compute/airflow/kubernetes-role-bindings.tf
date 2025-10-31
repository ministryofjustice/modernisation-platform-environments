resource "kubernetes_role_binding" "airflow_execution" {
  metadata {
    name      = "airflow-execution"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.airflow_execution.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "airflow"
  }
}

resource "kubernetes_role_binding" "airflow_serviceaccount_management" {
  metadata {
    name      = "airflow-serviceaccount-management"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.airflow_serviceaccount_management.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "airflow-serviceaccount-management"
  }
}

resource "kubernetes_role_binding" "mwaa_execution" {
  metadata {
    name      = "mwaa-execution"
    namespace = kubernetes_namespace.mwaa.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.mwaa_execution.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "mwaa"
  }
}

resource "kubernetes_role_binding" "mwaa_serviceaccount_management" {
  metadata {
    name      = "mwaa-serviceaccount-management"
    namespace = kubernetes_namespace.mwaa.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.mwaa_serviceaccount_management.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "mwaa-serviceaccount-management"
  }
}

resource "kubernetes_role_binding" "mwaa_external_secrets" {
  metadata {
    name      = "mwaa-external-secrets"
    namespace = kubernetes_namespace.mwaa.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.mwaa_external_secrets.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "mwaa-external-secrets"
  }
}

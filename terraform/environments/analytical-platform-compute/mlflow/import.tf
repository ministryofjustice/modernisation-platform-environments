# This file is used to import the existing k8s resources into Terraform state.
# Will be deleted after the import is complete and the state file is updated.

############################
# Namespace
############################

import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? { "0" = "mlflow" } : {}
  to       = kubernetes_namespace_v1.mlflow[0]
  id       = each.value
}

removed {
  from = kubernetes_namespace.mlflow
  lifecycle {
    destroy = false
  }
}

############################
# Secrets (import into v1)
############################

import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? { "0" = "mlflow/mlflow-admin" } : {}
  to       = kubernetes_secret_v1.mlflow_admin[0]
  id       = each.value
}

import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? { "0" = "mlflow/mlflow-auth-rds" } : {}
  to       = kubernetes_secret_v1.mlflow_auth_rds[0]
  id       = each.value
}

import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? { "0" = "mlflow/mlflow-flask-server-secret-key" } : {}
  to       = kubernetes_secret_v1.mlflow_flask_server_secret_key[0]
  id       = each.value
}

import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? { "0" = "mlflow/mlflow-rds" } : {}
  to       = kubernetes_secret_v1.mlflow_rds[0]
  id       = each.value
}

############################
# Prevent deletion of old resources
############################

removed {
  from = kubernetes_secret.mlflow_admin
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_secret.mlflow_auth_rds
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_secret.mlflow_flask_server_secret_key
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_secret.mlflow_rds
  lifecycle {
    destroy = false
  }
}
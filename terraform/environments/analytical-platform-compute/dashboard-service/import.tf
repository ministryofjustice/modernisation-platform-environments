# This file is used to import the existing k8s reesources and iam polcies into Terraform state.Will be deleted after the import is complete and the state file is updated.

#### NAMESPACE ######
import {
  for_each = terraform.workspace != "analytical-platform-compute-test" ? { "0" = "dashboard-service" } : {}
  to       = kubernetes_namespace_v1.dashboard_service[0]
  id       = each.value
}

removed {
  from = kubernetes_namespace.dashboard_service
  lifecycle {
    destroy = false
  }
}

#external secrets
import {
  for_each = terraform.workspace != "analytical-platform-compute-test" ? { "0" = "dashboard-service/dashboard-service-rds" } : {}
  to       = kubernetes_secret_v1.dashboard_service_rds[0]
  id       = each.value

}

removed {
  from = kubernetes_secret.dashboard_service_rds
  lifecycle {
    destroy = false
  }
}

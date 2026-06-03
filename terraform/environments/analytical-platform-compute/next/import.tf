# This file is used to import the existing k8s reesources into Terraform state.Will be deleted after the import is complete and the state file is updated.

# secret 
import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? toset(["0"]) : toset([])
  to       = kubernetes_secret_v1.rds[0]
  id       = "next/rds"
}

removed {
  from = kubernetes_secret.rds
  lifecycle {
    destroy = false
  }
}


# next namespace
import {
  for_each = terraform.workspace == "analytical-platform-compute-development" ? toset(["0"]) : toset([])
  to       = kubernetes_namespace_v1.main[0]
  id       = local.component_name
}
removed {
  from = kubernetes_namespace.main
  lifecycle {
    destroy = false
  }
}
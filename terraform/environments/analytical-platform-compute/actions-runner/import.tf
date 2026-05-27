# This file is used to import the existing Kubernetes namespace for actions runners into Terraform state.Will be deleted after the import is complete and the state file is updated.
import {
  for_each = terraform.workspace == "analytical-platform-compute-production" ? { "0" = "actions-runners" } : {}
  to       = kubernetes_namespace_v1.actions_runners[0]
  id       = each.value
}

removed {
  from = kubernetes_namespace.actions_runners

  lifecycle {
    destroy = false
  }
}

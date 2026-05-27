# This file is used to import the existing Kubernetes namespace for actions runners into Terraform state.Will be deleted after the import is complete and the state file is updated.
import {
  to = kubernetes_namespace_v1.actions_runners[0]
  id = "actions-runners"
}

removed {
  from = kubernetes_namespace.actions_runners

  lifecycle {
    destroy = false
  }
}

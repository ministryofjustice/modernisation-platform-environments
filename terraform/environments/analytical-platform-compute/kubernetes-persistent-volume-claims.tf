resource "kubernetes_persistent_volume_claim" "actions_runner_cache" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name      = "actions-runner-cache"
    namespace = "actions-runners"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "100Gi"
      }
    }
    storage_class_name = "efs-sc"
    volume_name        = kubernetes_persistent_volume.actions_runner_cache.metadata[0].name
  }
  wait_until_bound = false
}

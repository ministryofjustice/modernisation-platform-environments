resource "kubernetes_persistent_volume" "actions_runner_cache" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name = "actions-runner-cache"
  }
  spec {
    capacity = {
      storage = "100Gi"
    }
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "efs-sc"
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${module.actions_runner_cache_efs[0].id}::${module.actions_runner_cache_efs[0].access_points["cache"].id}"
      }
    }
  }
}

resource "kubernetes_annotations" "gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"

  force = true

  metadata {
    name = "gp2"
  }

  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

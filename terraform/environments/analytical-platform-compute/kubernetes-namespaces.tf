resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

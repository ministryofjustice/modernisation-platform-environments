resource "helm_release" "kyverno" {
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
  version    = "3.2.2"
  namespace  = kubernetes_namespace.kyverno.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/kyverno/values.yml.tftpl",
      {}
    )
  ]
}

resource "helm_release" "aws_cloudwatch_metrics" {
  name       = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.11"
  namespace  = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/amazon-cloudwatch-metrics/values.yml.tftpl",
      {
        cluster_name = module.eks.cluster_name
      }
    )
  ]

  depends_on = [module.aws_cloudwatch_metrics_pod_identity]
}

/* Policy */
resource "helm_release" "kyverno" {
  /* https://artifacthub.io/packages/helm/kyverno/kyverno */
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

/* AWS Observability */
/*
  There is an ongoing issue with aws-cloudwatch-metrics as it doesn't properly support IMDSv2 (https://github.com/aws/amazon-cloudwatch-agent/issues/1101)
  Therefore for this to work properly, I've set hostNetwork to true in src/helm/amazon-cloudwatch-metrics/values.yml.tftpl
  The DaemonSet uses the node role to which has arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy attached
  The Helm chart also doesn't have support for IRSA, so a EKS Pod Identity has been been made ready to use module.aws_cloudwatch_metrics_pod_identity
*/
resource "helm_release" "aws_cloudwatch_metrics" {
  /* https://artifacthub.io/packages/helm/aws/aws-cloudwatch-metrics */
  name       = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.11"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/aws-cloudwatch-metrics/values.yml.tftpl",
      {
        cluster_name = module.eks.cluster_name
      }
    )
  ]

  depends_on = [module.aws_cloudwatch_metrics_pod_identity]
}

resource "helm_release" "aws_for_fluent_bit" {
  /* https://artifacthub.io/packages/helm/aws/aws-for-fluent-bit */
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.33"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/aws-for-fluent-bit/values.yml.tftpl",
      {
        aws_region                = data.aws_region.current.name
        cluster_name              = module.eks.cluster_name
        cloudwatch_log_group_name = module.eks_log_group.cloudwatch_log_group_name
        eks_role_arn              = module.aws_for_fluent_bit_iam_role.iam_role_arn
      }
    )
  ]

  depends_on = [module.aws_for_fluent_bit_iam_role]
}

resource "helm_release" "amazon_prometheus_proxy" {
  /* https://artifacthub.io/packages/helm/prometheus-community/prometheus */
  name       = "amazon-prometheus-proxy"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "25.21.0"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/amazon-prometheus-proxy/values.yml.tftpl",
      {
        aws_region       = data.aws_region.current.name
        eks_role_arn     = module.amazon_prometheus_proxy_iam_role.iam_role_arn
        amp_workspace_id = aws_prometheus_workspace.main.id
      }
    )
  ]

  depends_on = [module.amazon_prometheus_proxy_iam_role]
}

/* Cluster Autoscaler */
resource "helm_release" "cluster_autoscaler" {
  /* https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler */
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.37.0"
  namespace  = "kube-system"

  values = [
    templatefile(
      "${path.module}/src/helm/cluster-autoscaler/values.yml.tftpl",
      {
        aws_region   = data.aws_region.current.name
        cluster_name = module.eks.cluster_name
        eks_role_arn = module.cluster_autoscaler_iam_role.iam_role_arn
      }
    )
  ]
  depends_on = [module.cluster_autoscaler_iam_role]
}

/* External DNS */
resource "helm_release" "external_dns" {
  /* https://artifacthub.io/packages/helm/external-dns/external-dns */
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.14.4"
  namespace  = "kube-system"
  values = [
    templatefile(
      "${path.module}/src/helm/external-dns/values.yml.tftpl",
      {
        domain_filter = local.environment_configuration.route53_zone
        eks_role_arn  = module.external_dns_iam_role.iam_role_arn
        txt_owner_id  = module.eks.cluster_name
      }
    )
  ]
  depends_on = [module.external_dns_iam_role]
}

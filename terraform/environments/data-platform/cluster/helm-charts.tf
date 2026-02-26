resource "helm_release" "cilium" {
  /* https://artifacthub.io/packages/helm/cilium/cilium */

  name       = "cilium"
  repository = "oci://quay.io/cilium/charts"
  chart      = "cilium"
  version    = local.cluster_configuration.helm_chart_versions.cilium
  namespace  = "kube-system"

  wait = false

  values = [
    templatefile(
      "${path.module}/configuration/helm/cilium/values.yml.tftpl",
      {
        cluster_name   = local.eks_cluster_name
        k8sServiceHost = trimprefix(module.eks.cluster_endpoint, "https://")
      }
    )
  ]

  depends_on = [
    module.eks,
    kubernetes_manifest.gateway_api_crd
  ]
}

resource "helm_release" "coredns" {
  /* https://artifacthub.io/packages/helm/coredns/coredns */

  name       = "coredns"
  repository = "oci://ghcr.io/coredns/charts"
  chart      = "coredns"
  version    = local.cluster_configuration.helm_chart_versions.coredns
  namespace  = "kube-system"

  wait = false

  values = [
    templatefile(
      "${path.module}/configuration/helm/coredns/values.yml.tftpl",
      {}
    )
  ]
}

resource "helm_release" "kyverno" {
  /* https://artifacthub.io/packages/helm/kyverno/kyverno */
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
  version    = local.cluster_configuration.helm_chart_versions.kyverno
  namespace  = module.kyverno_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/kyverno/values.yml.tftpl",
      {}
    )
  ]

  depends_on = [
    helm_release.cilium,
    helm_release.coredns
  ]
}

resource "helm_release" "cluster_autoscaler" {
  /* https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler */
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = local.cluster_configuration.helm_chart_versions.cluster_autoscaler
  namespace  = module.cluster_autoscaler_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/cluster-autoscaler/values.yml.tftpl",
      {
        aws_region                = data.aws_region.current.region
        cluster_name              = module.eks.cluster_name
        eks_role_arn              = module.cluster_autoscaler_iam_role.arn
        service_monitor_namespace = module.cluster_autoscaler_namespace.name
      }
    )
  ]
  depends_on = [module.cluster_autoscaler_iam_role]
}

resource "helm_release" "prometheus" {
  /* https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack */
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = local.cluster_configuration.helm_chart_versions.kube_prometheus_stack
  namespace  = module.prometheus_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/prometheus/values.yml.tftpl",
      {
        aws_region       = data.aws_region.current.region
        eks_role_arn     = module.prometheus_iam_role.arn
        amp_workspace_id = module.prometheus.workspace_id
      }
    )
  ]

  depends_on = [kubernetes_manifest.prometheus_operator_crd]
}

resource "helm_release" "fluent_bit" {
  /* https://artifacthub.io/packages/helm/aws/aws-for-fluent-bit */
  name       = "fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = local.cluster_configuration.helm_chart_versions.fluent_bit
  namespace  = module.fluent_bit_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/fluent-bit/values.yml.tftpl",
      {
        aws_region                = data.aws_region.current.region
        cluster_name              = module.eks.cluster_name
        cloudwatch_log_group_name = module.eks_application_logs_log_group.cloudwatch_log_group_name
        eks_role_arn              = module.fluent_bit_iam_role.arn
      }
    )
  ]
}

resource "helm_release" "cert_manager" {
  /* https://artifacthub.io/packages/helm/cert-manager/cert-manager */
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = local.cluster_configuration.helm_chart_versions.cert_manager
  namespace  = module.cert_manager_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/cert-manager/values.yml.tftpl",
      {
        eks_role_arn = module.cert_manager_iam_role.arn
      }
    )
  ]
}

resource "helm_release" "cert_manager_issuers" {
  name      = "cert-manager-issuers"
  chart     = "./src/helm/charts/cert-manager-issuers"
  namespace = module.cert_manager_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/cert-manager-issuers/values.yml.tftpl",
      {
        acme_email = "dataplatform@digital.justice.gov.uk"
        aws_region = data.aws_region.current.region
      }
    )
  ]
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "external_dns" {
  /* https://artifacthub.io/packages/helm/external-dns/external-dns */
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = local.cluster_configuration.helm_chart_versions.external_dns
  namespace  = module.external_dns_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/external-dns/values.yml.tftpl",
      {
        domain_filters = local.cluster_configuration.route53_zones
        eks_role_arn   = module.external_dns_iam_role.arn
        txt_owner_id   = module.eks.cluster_name
      }
    )
  ]
}

resource "helm_release" "shared_services_gateway" {
  name      = "shared-services-gateway"
  chart     = "./src/helm/charts/shared-services-gateway"
  namespace = module.shared_services_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/shared-services-gateway/values.yml.tftpl",
      {
        gateway_hostname = local.cluster_configuration.shared_services_gateway_hostname
      }
    )
  ]
  depends_on = [
    helm_release.cert_manager,
    helm_release.external_dns
  ]
}

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

resource "helm_release" "karpenter_crd" {
  /* https://github.com/aws/karpenter-provider-aws/releases */

  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = local.cluster_configuration.helm_chart_versions.karpenter_crd
  namespace  = module.karpenter_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/karpenter-crd/values.yml.tftpl",
      {
        service_namespace = module.karpenter_namespace.name
      }
    )
  ]
  depends_on = [
    aws_iam_service_linked_role.spot,
    module.karpenter
  ]
}

resource "helm_release" "karpenter" {
  /* https://github.com/aws/karpenter-provider-aws/releases */

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = local.cluster_configuration.helm_chart_versions.karpenter
  namespace  = module.karpenter_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/karpenter/values.yml.tftpl",
      {
        service_account_name = module.karpenter.service_account
        cluster_name         = module.eks.cluster_name
        cluster_endpoint     = module.eks.cluster_endpoint
        interruption_queue   = module.karpenter.queue_name
      }
    )
  ]
  depends_on = [
    aws_iam_service_linked_role.spot,
    module.karpenter,
    helm_release.karpenter_crd
  ]
}

resource "helm_release" "karpenter_configuration" {
  name      = "karpenter-configuration"
  chart     = "./src/helm/charts/karpenter-configuration"
  namespace = module.karpenter_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/karpenter-configuration/values.yml.tftpl",
      {
        cluster_name    = module.eks.cluster_name
        cluster_version = module.eks.cluster_version
        ebs_kms_key_id  = module.eks_ebs_kms_key.key_id
        node_role       = module.karpenter.node_iam_role_name
        node_version    = local.cluster_configuration.bottlerocket_version
        subnet_ids      = data.aws_subnets.private.ids
        security_group_ids = [
          module.eks.cluster_primary_security_group_id,
          module.node_security_group.security_group_id,
        ]
        ec2_node_class_tags = {
          # This enhanced logic ensures that boolean values in local.tags are converted to strings, which is necessary for Helm chart compatibility.
          # for example. local.tags.is-production = true will be converted to "is-production" = "true"
          for key, value in merge(
            {
              "compute.data-platform.service.justice.gov.uk/node" = "application"
              "compute.data-platform.service.justice.gov.uk/type" = "karpenter"
            },
            local.tags
          ) : key => tostring(value)
        }
      }
    )
  ]
  depends_on = [helm_release.karpenter]
}

resource "helm_release" "cloudwatch_metrics" {
  /* https://artifacthub.io/packages/helm/aws/aws-cloudwatch-metrics */

  name       = "cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = local.cluster_configuration.helm_chart_versions.cloudwatch_metrics
  namespace  = module.cloudwatch_metrics_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/cloudwatch-metrics/values.yml.tftpl",
      {
        cluster_name = module.eks.cluster_name
      }
    )
  ]
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

resource "helm_release" "external_secrets" {
  /* https://artifacthub.io/packages/helm/external-secrets-operator/external-secrets */

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = local.cluster_configuration.helm_chart_versions.external_secrets
  namespace  = module.external_secrets_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/external-secrets/values.yml.tftpl",
      {
        eks_role_arn = module.external_secrets_iam_role.arn
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

resource "helm_release" "keda" {
  /* https://artifacthub.io/packages/helm/kedacore/keda */

  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = local.cluster_configuration.helm_chart_versions.keda
  namespace  = module.keda_namespace.name
  values = [
    templatefile(
      "${path.module}/configuration/helm/keda/values.yml.tftpl",
      {}
    )
  ]
}

# Velero CRD installation is failing due to changes with Bitnami's kubectl image https://github.com/vmware-tanzu/helm-charts/issues/698
# TODO: Look at https://aws.amazon.com/about-aws/whats-new/2025/11/aws-backup-supports-amazon-eks/
# resource "helm_release" "velero" {
#   /* https://artifacthub.io/packages/helm/vmware-tanzu/velero */

#   name       = "velero"
#   repository = "https://vmware-tanzu.github.io/helm-charts"
#   chart      = "velero"
#   version    = local.cluster_configuration.helm_chart_versions.velero
#   namespace  = module.velero_namespace.name
#   values = [
#     templatefile(
#       "${path.module}/configuration/helm/velero/values.yml.tftpl",
#       {
#         aws_region                = data.aws_region.current.region
#         eks_role_arn              = module.velero_iam_role.arn
#         kubectl_version           = local.cluster_configuration.extra_versions.velero_kubectl
#         velero_aws_plugin_version = local.cluster_configuration.extra_versions.velero_plugin_aws
#         velero_bucket             = module.velero_s3_bucket.s3_bucket_id
#         velero_prefix             = module.eks.cluster_name
#       }
#     )
#   ]
# }

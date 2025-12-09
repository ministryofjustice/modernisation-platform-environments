/* Policy */
resource "helm_release" "kyverno" {
  /* https://artifacthub.io/packages/helm/kyverno/kyverno */
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
  version    = "3.6.1"
  namespace  = kubernetes_namespace.kyverno.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/kyverno/values.yml.tftpl",
      {}
    )
  ]
}

/* AWS Observability */
/*
  There is an ongoing issue with aws-cloudwatch-metrics as it doesn't properly support IMDSv2 (https://github.com/aws/amazon-cloudwatch-agent/issues/1101)
  Therefore for this to work properly, I've set hostNetwork to true in src/helm/values/amazon-cloudwatch-metrics/values.yml.tftpl
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
      "${path.module}/src/helm/values/aws-cloudwatch-metrics/values.yml.tftpl",
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
  version    = "0.1.35"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/aws-for-fluent-bit/values.yml.tftpl",
      {
        aws_region                = data.aws_region.current.region
        cluster_name              = module.eks.cluster_name
        cloudwatch_log_group_name = module.eks_log_group.cloudwatch_log_group_name
        eks_role_arn              = module.aws_for_fluent_bit_iam_role.iam_role_arn
      }
    )
  ]

  depends_on = [module.aws_for_fluent_bit_iam_role]
}

resource "helm_release" "amazon_prometheus_proxy" {
  /* https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack */
  /* 
    If you are upgrading this chart, check whether the CRD version needs updating
    https://github.com/prometheus-operator/prometheus-operator/releases
  */
  name       = "amazon-prometheus-proxy"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "80.0.0"
  namespace  = kubernetes_namespace.aws_observability.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/amazon-prometheus-proxy/values.yml.tftpl",
      {
        aws_region       = data.aws_region.current.region
        eks_role_arn     = module.amazon_prometheus_proxy_iam_role.iam_role_arn
        amp_workspace_id = module.managed_prometheus.workspace_id
      }
    )
  ]

  depends_on = [
    kubernetes_manifest.prometheus_operator_crds,
    module.amazon_prometheus_proxy_iam_role
  ]
}

/* Cluster Autoscaler */
resource "helm_release" "cluster_autoscaler" {
  /* https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler */
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.53.0"
  namespace  = kubernetes_namespace.cluster_autoscaler.metadata[0].name

  values = [
    templatefile(
      "${path.module}/src/helm/values/cluster-autoscaler/values.yml.tftpl",
      {
        aws_region                = data.aws_region.current.region
        cluster_name              = module.eks.cluster_name
        eks_role_arn              = module.cluster_autoscaler_iam_role.iam_role_arn
        service_monitor_namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name
      }
    )
  ]
  depends_on = [module.cluster_autoscaler_iam_role]
}

/* Karpenter */
resource "helm_release" "karpenter_crd" {
  /* https://github.com/aws/karpenter-provider-aws/releases */
  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = "1.8.2"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name

  values = [
    templatefile(
      "${path.module}/src/helm/values/karpenter-crd/values.yml.tftpl",
      {
        service_namespace = kubernetes_namespace.karpenter.metadata[0].name
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
  version    = "1.8.2"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name

  values = [
    templatefile(
      "${path.module}/src/helm/values/karpenter/values.yml.tftpl",
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
  namespace = kubernetes_namespace.karpenter.metadata[0].name

  values = [
    templatefile(
      "${path.module}/src/helm/values/karpenter-configuration/values.yml.tftpl",
      {
        cluster_name    = module.eks.cluster_name
        cluster_version = module.eks.cluster_version
        ebs_kms_key_id  = module.eks_ebs_kms.key_id
        node_role       = module.karpenter.node_iam_role_name
        node_version    = local.environment_configuration.eks_node_version
      }
    )
  ]
  depends_on = [helm_release.karpenter]
}

/* External DNS */
resource "helm_release" "external_dns" {
  /* https://artifacthub.io/packages/helm/external-dns/external-dns */
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.19.0"
  namespace  = kubernetes_namespace.external_dns.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/external-dns/values.yml.tftpl",
      {
        domain_filter = local.environment_configuration.route53_zone
        eks_role_arn  = module.external_dns_iam_role.iam_role_arn
        txt_owner_id  = module.eks.cluster_name
      }
    )
  ]
  depends_on = [module.external_dns_iam_role]
}

/* Cert Manager */
resource "helm_release" "cert_manager" {
  /* https://artifacthub.io/packages/helm/cert-manager/cert-manager */
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.19.1"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/cert-manager/values.yml.tftpl",
      {
        eks_role_arn = module.cert_manager_iam_role.iam_role_arn
      }
    )
  ]
  depends_on = [module.cert_manager_iam_role]
}

resource "helm_release" "cert_manager_issuers" {
  name      = "cert-manager-issuers"
  chart     = "./src/helm/charts/cert-manager-issuers"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name

  values = [
    templatefile(
      "${path.module}/src/helm/values/cert-manager-issuers/values.yml.tftpl",
      {
        acme_email               = "analytical-platform+compute-cert-manager@digital.justice.gov.uk"
        aws_region               = data.aws_region.current.region
        http_issuer_ingress_name = "default"
      }
    )
  ]
  depends_on = [helm_release.cert_manager]
}

/* Ingress NGINX */
resource "helm_release" "ingress_nginx_default_certificate" {
  name      = "ingress-nginx-default-certificate"
  chart     = "./src/helm/charts/ingress-nginx-default-certificate"
  namespace = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    templatefile(
      "${path.module}/src/helm/values/ingress-nginx-default-certificate/values.yml.tftpl",
      {
        default_certificate_dns_name = "*.${local.environment_configuration.route53_zone}"
      }
    )
  ]
  depends_on = [helm_release.cert_manager_issuers]
}

resource "helm_release" "ingress_nginx" {
  /* https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx */
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.14.1"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/ingress-nginx/values.yml.tftpl",
      {
        default_ssl_certificate   = "${kubernetes_namespace.ingress_nginx.metadata[0].name}/default-certificate"
        ingress_hostname          = "ingress.${local.environment_configuration.route53_zone}"
        service_monitor_namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
      }
    )
  ]
  depends_on = [helm_release.ingress_nginx_default_certificate]
}

/* External Secrets */
resource "helm_release" "external_secrets" {
  /* https://artifacthub.io/packages/helm/external-secrets-operator/external-secrets */
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "1.1.1"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/external-secrets/values.yml.tftpl",
      {
        eks_role_arn = module.external_secrets_iam_role.iam_role_arn
      }
    )
  ]
  depends_on = [module.external_secrets_iam_role]
}

resource "helm_release" "external_secrets_cluster_secret_store" {
  name      = "external-secrets-cluster-secret-store"
  chart     = "./src/helm/charts/external-secrets-cluster-secret-store"
  namespace = kubernetes_namespace.external_secrets.metadata[0].name

  depends_on = [helm_release.external_secrets]
}

/* KEDA */
resource "helm_release" "keda" {
  /* https://artifacthub.io/packages/helm/kedacore/keda */
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.18.2"
  namespace  = kubernetes_namespace.keda.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/keda/values.yml.tftpl",
      {}
    )
  ]
}

/* Velero */
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "11.2.0"
  namespace  = kubernetes_namespace.velero.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/velero/values.yml.tftpl",
      {
        eks_role_arn              = module.velero_iam_role.iam_role_arn
        velero_aws_plugin_version = "v1.13.1"
        velero_bucket             = module.velero_s3_bucket.s3_bucket_id
        velero_prefix             = module.eks.cluster_name
        aws_region                = data.aws_region.current.region
      }
    )
  ]
}

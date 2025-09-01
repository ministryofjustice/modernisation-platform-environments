module "ebs_csi_driver_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix      = "ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "efs_csi_driver_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix      = "efs-csi-driver"
  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "aws_cloudwatch_network_flow_monitor_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix = "aws-cloudwatch-network-flow-monitor"

  role_policy_arns = {
    CloudWatchNetworkFlowMonitorAgentPublishPolicy = "arn:aws:iam::aws:policy/CloudWatchNetworkFlowMonitorAgentPublishPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["amazon-network-flow-monitor:aws-network-flow-monitor-agent-service-account"]
    }
  }

  tags = local.tags
}

module "cluster_autoscaler_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.cluster_autoscaler.metadata[0].name}:cluster-autoscaler"]
    }
  }

  tags = local.tags
}

module "external_dns_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix              = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.route53_zone_zone.arn]


  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.external_dns.metadata[0].name}:external-dns"]
    }
  }

  tags = local.tags
}

module "cert_manager_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix              = "cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.route53_zone_zone.arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.cert_manager.metadata[0].name}:cert-manager"]
    }
  }

  tags = local.tags
}

module "external_secrets_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix               = "external-secrets"
  attach_external_secrets_policy = true
  external_secrets_kms_key_arns  = [module.common_secrets_manager_kms.key_arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.external_secrets.metadata[0].name}:external-secrets"]
    }
  }

  tags = local.tags
}

module "aws_for_fluent_bit_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix = "aws-for-fluent-bit"

  role_policy_arns = {
    CloudWatchAgentServerPolicy   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    EKSClusterLogsKMSAccessPolicy = module.eks_cluster_logs_kms_access_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.aws_observability.metadata[0].name}:aws-for-fluent-bit"]
    }
  }

  tags = local.tags
}

module "amazon_prometheus_proxy_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix = "amazon-prometheus-proxy"

  role_policy_arns = {
    AmazonManagedPrometheusProxy = module.amazon_prometheus_proxy_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.aws_observability.metadata[0].name}:amazon-prometheus-proxy"]
    }
  }

  tags = local.tags
}

module "vpc_cni_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix      = "vpc-cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "velero_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name_prefix      = "velero"
  attach_velero_policy  = true
  velero_s3_bucket_arns = [module.velero_s3_bucket.s3_bucket_arn]

  role_policy_arns = {
    VeleroKMSAccessPolicy = module.velero_kms_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.velero.metadata[0].name}:velero-server"]
    }
  }

  tags = local.tags
}

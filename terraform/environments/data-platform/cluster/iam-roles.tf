module "aws_network_flow_monitor_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "aws-network-flow-monitor"

  policies = {
    CloudWatchNetworkFlowMonitorAgentPublishPolicy = "arn:aws:iam::aws:policy/CloudWatchNetworkFlowMonitorAgentPublishPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["amazon-network-flow-monitor:aws-network-flow-monitor-agent-service-account"]
    }
  }
}

module "ebs_csi_driver_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "ebs-csi-driver"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "efs_csi_driver_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "efs-csi-driver"

  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

module "cluster_autoscaler_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${module.cluster_autoscaler_namespace.name}:cluster-autoscaler"]
    }
  }
}

module "prometheus_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "prometheus"

  policies = {
    Prometheus = module.prometheus_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${module.prometheus_namespace.name}:prometheus"]
    }
  }
}

module "fluent_bit_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "fluent-bit"

  policies = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    EKSLogsKMSPolicy            = module.eks_logs_kms_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${module.fluent_bit_namespace.name}:fluent-bit"]
    }
  }

  tags = local.tags
}

module "cert_manager_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [for zone in data.aws_route53_zone.route53_zones : zone.arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${module.cert_manager_namespace.name}:cert-manager"]
    }
  }
}

module "external_dns_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role-for-service-accounts?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name = "external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [for zone in data.aws_route53_zone.route53_zones : zone.arn]


  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${module.external_dns_namespace.name}:external-dns"]
    }
  }
}

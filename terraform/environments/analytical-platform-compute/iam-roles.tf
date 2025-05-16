module "vpc_cni_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

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

module "ebs_csi_driver_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

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
  version = "5.55.0"

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

module "aws_for_fluent_bit_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

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
  version = "5.55.0"

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

module "cluster_autoscaler_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

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
  version = "5.55.0"

  role_name_prefix              = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [module.route53_zones.route53_zone_zone_arn[local.environment_configuration.route53_zone]]

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
  version = "5.55.0"

  role_name_prefix              = "cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [module.route53_zones.route53_zone_zone_arn[local.environment_configuration.route53_zone]]

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
  version = "5.55.0"

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

module "mlflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  role_name_prefix = "mlflow"

  role_policy_arns = {
    MlflowPolicy = module.mlflow_iam_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.mlflow.metadata[0].name}:mlflow"]
    }
  }

  tags = local.tags
}

module "lake_formation_share_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  create_role       = true
  role_requires_mfa = false

  role_name_prefix = "lake-formation-share"

  number_of_custom_role_policy_arns = 2

  custom_role_policy_arns = [
    module.analytical_platform_lake_formation_share_policy.arn,
    "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  ]

  trusted_role_arns = [
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-management-production"]}:root",
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-compute-development"]}:root"
  ]

  tags = local.tags
}

module "analytical_platform_ui_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  create_role = true

  role_name_prefix = "analytical-platform-ui"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.ui.metadata[0].name}:ui"]
    }
  }
  role_policy_arns = {
    "lake_formation_and_quicksight"      = module.analytical_platform_lake_formation_share_policy.arn
    "lake_formation_cross_account_share" = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  }
  tags = local.tags
}

module "analytical_platform_control_panel_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  allow_self_assume_role = true
  trusted_role_arns = [
    format("arn:aws:iam::%s:root", local.environment_management.account_ids[local.analytical_platform_environment])

  ]
  create_role       = true
  role_requires_mfa = false
  role_name         = "analytical-platform-control-panel"

  custom_role_policy_arns = [
    module.analytical_platform_lake_formation_share_policy.arn,
    "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  ]
  number_of_custom_role_policy_arns = 2

  tags = local.tags
}

module "analytical_platform_data_eng_dba_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  allow_self_assume_role = false
  trusted_role_arns      = formatlist("arn:aws:iam::%s:root", [local.environment_management.account_ids[local.analytical_platform_environment], local.environment_management.account_ids["analytical-platform-management-production"]])
  create_role            = true
  role_requires_mfa      = false
  role_name              = "analytical-platform-data-engineering-database-access"

  custom_role_policy_arns = [
    module.analytical_platform_lake_formation_share_policy.arn,
    "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
  ]
  number_of_custom_role_policy_arns = 2

  tags = local.tags
}

module "lake_formation_to_data_production_mojap_derived_tables_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  create_role       = true
  role_requires_mfa = false

  role_name = "lake-formation-data-production-data-access"

  custom_role_policy_arns = [
    module.data_production_mojap_derived_bucket_lake_formation_policy.arn,
  ]

  trusted_role_actions = [
    "sts:AssumeRole",
    "sts:SetContext"
  ]

  trusted_role_services = [
    "glue.amazonaws.com",
    "lakeformation.amazonaws.com"
  ]

  tags = local.tags
}

module "copy_apdp_cadet_metadata_to_compute_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  allow_self_assume_role = false
  trusted_role_arns = [
    "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/create-a-derived-table",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.data_engineering_sso_role.names)}",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.eks_sso_access_role.names)}",
  ]
  create_role       = true
  role_requires_mfa = false
  role_name         = "copy-apdp-cadet-metadata-to-compute"

  custom_role_policy_arns = [module.copy_apdp_cadet_metadata_to_compute_policy.arn]

  tags = local.tags
}

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

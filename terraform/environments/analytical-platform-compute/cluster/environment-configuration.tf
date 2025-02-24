locals {
  environment_configurations = {
    development = {
      /* EKS */
      eks_sso_access_role = "modernisation-platform-sandbox"
      eks_cluster_version = "1.32"
      eks_node_version    = "1.32.0-cacc4ce9"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.4-eksbuild.2"
        kube_proxy             = "v1.32.0-eksbuild.2"
        aws_ebs_csi_driver     = "v1.39.0-eksbuild.1"
        aws_efs_csi_driver     = "v2.1.4-eksbuild.1"
        aws_guardduty_agent    = "v1.8.1-eksbuild.2"
        eks_pod_identity_agent = "v1.3.4-eksbuild.1"
        vpc_cni                = "v1.19.2-eksbuild.5"
      }
    }
    test = {
      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.32"
      eks_node_version    = "1.32.0-cacc4ce9"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.4-eksbuild.2"
        kube_proxy             = "v1.32.0-eksbuild.2"
        aws_ebs_csi_driver     = "v1.39.0-eksbuild.1"
        aws_efs_csi_driver     = "v2.1.4-eksbuild.1"
        aws_guardduty_agent    = "v1.8.1-eksbuild.2"
        eks_pod_identity_agent = "v1.3.4-eksbuild.1"
        vpc_cni                = "v1.19.2-eksbuild.5"
      }
    }
    production = {
      /* EKS */
      eks_sso_access_role = "modernisation-platform-developer"
      eks_cluster_version = "1.32"
      eks_node_version    = "1.32.0-cacc4ce9"
      eks_cluster_addon_versions = {
        coredns                = "v1.11.4-eksbuild.2"
        kube_proxy             = "v1.32.0-eksbuild.2"
        aws_ebs_csi_driver     = "v1.39.0-eksbuild.1"
        aws_efs_csi_driver     = "v2.1.4-eksbuild.1"
        aws_guardduty_agent    = "v1.8.1-eksbuild.2"
        eks_pod_identity_agent = "v1.3.4-eksbuild.1"
        vpc_cni                = "v1.19.2-eksbuild.5"
      }
    }
  }
}

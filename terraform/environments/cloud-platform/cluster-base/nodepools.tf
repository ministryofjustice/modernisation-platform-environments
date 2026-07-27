locals {
  bu_accounts = jsondecode(file("${path.module}/../accounts.json"))

  mp_environments = concat(
    [
      "cloud-platform-preproduction",
      "cloud-platform-nonlive",
      "cloud-platform-live"
    ],
    local.bu_accounts.accounts
  )

  workspace_environment = element(reverse(split("-", terraform.workspace)), 0)
  cluster_environment   = contains(local.mp_environments, terraform.workspace) ? local.workspace_environment : "development_cluster"
  cp_vpc_name           = local.cluster_environment == "development_cluster" ? "cloud-platform-development" : terraform.workspace
  cluster_name          = terraform.workspace

  # Double trimprefix due to mix of cloud-platform- and container-platform- prefixes
  workspace_slug = trimprefix(trimprefix(terraform.workspace, "cloud-platform-"), "container-platform-")

  node_role_name = split("/", data.aws_eks_cluster.cluster.compute_config[0].node_role_arn)[1]
  nodeclass_name = "${local.workspace_slug}-nodeclass"
}

resource "kubectl_manifest" "default_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: eks.amazonaws.com/v1
    kind: NodeClass
    metadata:
      name: ${local.nodeclass_name}
    spec:
      role: ${local.node_role_name}

      # Node subnets (primary CIDR)
      subnetSelectorTerms:
        - tags:
            SubnetType: "Private"
            environment-name: "${local.cp_vpc_name}"

      # Node security group
      securityGroupSelectorTerms:
        - tags:
            aws:eks:cluster-name: "${local.cluster_name}"

      # Pod subnets (secondary CIDR — 100.64.x.x)
      podSubnetSelectorTerms:
        - tags:
            SubnetType: "pod-private"
            Cluster: "${local.cp_vpc_name}"

      # Pod security group
      podSecurityGroupSelectorTerms:
        - tags:
            aws:eks:cluster-name: "${local.cluster_name}"

      tags:
        application: "moj-container-platform"
        business-unit: "octo"
  YAML
}
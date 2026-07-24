locals {
  nodeclass_name = "${local.workspace_slug}-nodeclass"
  default_nodepool_name  = "${local.workspace_slug}-default-nodepool"
  system_nodepool_name   = "${local.workspace_slug}-system-nodepool"
}

resource "kubectl_manifest" "default_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: eks.amazonaws.com/v1
    kind: NodeClass
    metadata:
      name: ${local.nodeclass_name}
    spec:
      role: ${local.node_role_name}

      #Enable EKS Auto Mode Network Policy Event Logs
      networkPolicyEventLogs: Enabled

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

resource "kubectl_manifest" "default_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: ${local.default_nodepool_name}
    spec:
      template:
        spec:
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: eks.amazonaws.com/instance-category
              operator: In
              values: ["m", "r"]
            - key: eks.amazonaws.com/instance-generation
              operator: Gt
              values: ["3"]

            - key: topology.kubernetes.io/zone
              operator: In
              values: ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
            - key: "eks.amazonaws.com/instance-size"
              operator: In
              values: ["4xlarge", "8xlarge"]
          nodeClassRef:
            group: eks.amazonaws.com
            kind: NodeClass
            name: ${local.nodeclass_name}
        metadata:
          labels:
            Terraform: "true"
            "container-platform.justice.gov.uk/default-ng": "true"
            Cluster: "${terraform.workspace}"
            Domain: ${local.workspace_slug}
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 60s
      limits:
        nodes: 50
  YAML

  depends_on = [kubectl_manifest.default_nodeclass]
}

resource "kubectl_manifest" "system_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: ${local.system_nodepool_name}
    spec:
      template:
        spec:
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: eks.amazonaws.com/instance-category
              operator: In
              values: ["m", "r"]
            - key: eks.amazonaws.com/instance-generation
              operator: Gt
              values: ["3"]

          nodeClassRef:
            group: eks.amazonaws.com
            kind: NodeClass
            name: ${local.nodeclass_name}
          taints:
            - key: system-node
              value: "true"
              effect: NoSchedule
        metadata:
          labels:
            Terraform: "true"
            "container-platform.justice.gov.uk/system-ng": "true"
            Cluster: "${terraform.workspace}"
            Domain: ${local.workspace_slug}
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 60s
      limits:
        nodes: 10
  YAML
  depends_on = [kubectl_manifest.default_nodeclass]
}

resource "kubectl_manifest" "amazon_vpc_cni_config" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: amazon-vpc-cni
      namespace: kube-system
    data:
      enable-network-policy-controller: "true"
YAML

  # Ensures Terraform updates the ConfigMap cleanly if EKS initialized it first
  force_new = false
}

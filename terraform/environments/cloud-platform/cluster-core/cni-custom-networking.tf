
resource "kubectl_manifest" "nodeclass_custom_networking" {
  yaml_body = <<-YAML
    apiVersion: eks.amazonaws.com/v1
    kind: NodeClass
    metadata:
      name: custom-networking
    spec:
      role: ${local.node_role_name}

      # Node subnets (primary CIDR)
      subnetSelectorTerms:
        - tags:
            SubnetType: "Private"
            Cluster: "${local.cp_vpc_name}"

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
  YAML
}

resource "kubectl_manifest" "nodepool_custom_networking" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: custom-networking
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
              values: ["c", "m", "r"]
            - key: eks.amazonaws.com/instance-generation
              operator: Gt
              values: ["4"]
          nodeClassRef:
            group: eks.amazonaws.com
            kind: NodeClass
            name: custom-networking
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 60s
      limits:
        cpu: "100"
        memory: 400Gi
  YAML

  depends_on = [kubectl_manifest.nodeclass_custom_networking]
}

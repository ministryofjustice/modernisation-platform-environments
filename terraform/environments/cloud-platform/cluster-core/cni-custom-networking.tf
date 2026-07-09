
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

      # tags:
      #   default_ng: "true"
      #   application: "moj-cloud-platform"
      #   business-unit: "platforms"
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

            - key: topology.kubernetes.io/zone
              operator: In
              values: ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
            - key: "eks.amazonaws.com/instance-cpu"
              operator: In
              values: ["4", "8", "16", "32"]
          nodeClassRef:
            group: eks.amazonaws.com
            kind: NodeClass
            name: custom-networking
        metadata:
          labels:
            Terraform: "true"
            "cloud-platform.justice.gov.uk/default-ng": "true"
            Cluster: "${terraform.workspace}"
            Domain: "${terraform.workspace}.container-platform.service.justice.gov.uk"
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 60s
      limits:
        cpu: "100"
        memory: 400Gi
        nodes: 100
  YAML

  depends_on = [kubectl_manifest.nodeclass_custom_networking]
}

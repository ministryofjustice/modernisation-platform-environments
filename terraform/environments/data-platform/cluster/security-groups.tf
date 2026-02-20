module "node_security_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=3cf4e1a48a4649179e8ea27308daf0b551cb0bfa" # v5.3.1

  name        = "${local.eks_cluster_name}-node"
  description = "EKS node security group"
  vpc_id      = data.aws_vpc.main.id

  egress_rules = ["all-all"]

  ingress_with_self = [
    {
      from_port   = 1025
      to_port     = 65535
      protocol    = "tcp"
      description = "Node to node ingress on ephemeral ports"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      description = "Node to node CoreDNS"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      description = "Node to node CoreDNS UDP"
    },
    {
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      description = "Cilium VXLAN overlay network"
    },
    {
      from_port   = 4240
      to_port     = 4240
      protocol    = "tcp"
      description = "Cilium health checks"
    },
    {
      from_port   = 4244
      to_port     = 4244
      protocol    = "tcp"
      description = "Cilium Hubble observability"
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "NLB via Network Firewall to node NodePort range"
      cidr_blocks = join(",", [for s in data.aws_subnet.firewall_subnet_details : s.cidr_block])
    },
  ]

  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Cluster API to node groups"
      source_security_group_id = module.eks.cluster_security_group_id
    },
    {
      from_port                = 10250
      to_port                  = 10250
      protocol                 = "tcp"
      description              = "Cluster API to node kubelets"
      source_security_group_id = module.eks.cluster_security_group_id
    },
    {
      from_port                = 4443
      to_port                  = 4443
      protocol                 = "tcp"
      description              = "Cluster API to node 4443/tcp webhook"
      source_security_group_id = module.eks.cluster_security_group_id
    },
    {
      from_port                = 6443
      to_port                  = 6443
      protocol                 = "tcp"
      description              = "Cluster API to node 6443/tcp webhook"
      source_security_group_id = module.eks.cluster_security_group_id
    },
    {
      from_port                = 8443
      to_port                  = 8443
      protocol                 = "tcp"
      description              = "Cluster API to node 8443/tcp webhook"
      source_security_group_id = module.eks.cluster_security_group_id
    },
    {
      from_port                = 9443
      to_port                  = 9443
      protocol                 = "tcp"
      description              = "Cluster API to node 9443/tcp webhook"
      source_security_group_id = module.eks.cluster_security_group_id
    },
    {
      from_port                = 10251
      to_port                  = 10251
      protocol                 = "tcp"
      description              = "Cluster API to node 10251/tcp webhook"
      source_security_group_id = module.eks.cluster_security_group_id
    },
  ]

  tags = {
    Name = "${local.eks_cluster_name}-node"
  }
}

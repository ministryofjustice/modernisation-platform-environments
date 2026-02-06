# EKS Managed Node Groups
# These are separated from the main cluster module to ensure they're created
# AFTER Cilium CNI is installed and ready

module "eks_managed_node_group_system" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "21.15.1"

  name         = "system"
  cluster_name = module.eks.cluster_name

  subnet_ids = data.aws_subnets.private.ids

  # Security groups required for nodes to join cluster
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  # Service CIDR required for Bottlerocket user data (EKS default)
  cluster_service_cidr = data.aws_eks_cluster.eks.kubernetes_network_config[0].service_ipv4_cidr

  # Instance configuration
  min_size       = 3
  max_size       = 10
  desired_size   = 3
  instance_types = ["m7a.large"]

  # Bottlerocket configuration
  ami_type                       = "BOTTLEROCKET_x86_64"
  use_latest_ami_release_version = false
  ami_release_version            = "1.54.0-5043decc"

  enable_monitoring = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  # Taint to prevent scheduling until Cilium is ready
  taints = {
    cilium = {
      key    = "node.cilium.io/agent-not-ready"
      value  = "true"
      effect = "NO_EXECUTE"
    }
  }

  tags = {
    Name = "${local.eks_cluster_name}-system"
  }

  # EBS volume configuration
  block_device_mappings = {
    xvdb = {
      device_name = "/dev/xvdb"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        encrypted             = true
        kms_key_id            = module.eks_ebs_kms_key.key_arn
        delete_on_termination = true
      }
    }
  }

  # IAM policies for node functionality
  iam_role_additional_policies = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy        = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  # Enable automatic node repair
  node_repair_config = {
    enabled = true
  }

  # Wait for Cilium manifests to be installed before creating nodes
  depends_on = [time_sleep.wait_for_cilium_manifests]
}

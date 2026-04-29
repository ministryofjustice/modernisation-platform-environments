data "aws_iam_policy_document" "test_eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test_eks_cluster_role" {
  name               = "${local.application_name}-${local.environment}-test-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.test_eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "test_eks_cluster_policy" {
  role       = aws_iam_role.test_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Validates SCP allows eks:CreateCluster.
resource "aws_eks_cluster" "test_eks_cluster" {
  name     = "${local.application_name}-${local.environment}-test-eks-cluster"
  role_arn = aws_iam_role.test_eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      data.aws_subnet.private_subnets_a.id,
      data.aws_subnet.private_subnets_b.id,
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.test_eks_cluster_policy]
}

data "aws_iam_policy_document" "test_eks_fargate_pod_execution_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test_eks_fargate_pod_execution_role" {
  name               = "${local.application_name}-${local.environment}-test-eks-fargate-pod-execution-role"
  assume_role_policy = data.aws_iam_policy_document.test_eks_fargate_pod_execution_assume_role.json
}

resource "aws_iam_role_policy_attachment" "test_eks_fargate_pod_execution_policy" {
  role       = aws_iam_role.test_eks_fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# Validates SCP allows eks:CreateFargateProfile.
resource "aws_eks_fargate_profile" "test_eks_fargate_profile" {
  cluster_name           = aws_eks_cluster.test_eks_cluster.name
  fargate_profile_name   = "${local.application_name}-${local.environment}-test-fargate-profile"
  pod_execution_role_arn = aws_iam_role.test_eks_fargate_pod_execution_role.arn
  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
  ]

  selector {
    namespace = "default"
  }

  depends_on = [aws_iam_role_policy_attachment.test_eks_fargate_pod_execution_policy]
}

data "aws_iam_policy_document" "test_eks_node_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test_eks_node_role" {
  name               = "${local.application_name}-${local.environment}-test-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.test_eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "test_eks_node_policy" {
  role       = aws_iam_role.test_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "test_eks_cni_policy" {
  role       = aws_iam_role.test_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "test_eks_ecr_readonly_policy" {
  role       = aws_iam_role.test_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Validates SCP allows eks:CreateNodegroup.
resource "aws_eks_node_group" "test_eks_node_group" {
  cluster_name    = aws_eks_cluster.test_eks_cluster.name
  node_group_name = "${local.application_name}-${local.environment}-test-node-group"
  node_role_arn   = aws_iam_role.test_eks_node_role.arn
  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
  ]
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.test_eks_node_policy,
    aws_iam_role_policy_attachment.test_eks_cni_policy,
    aws_iam_role_policy_attachment.test_eks_ecr_readonly_policy,
  ]
}

data "aws_iam_policy_document" "test_eks_pod_identity_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test_eks_pod_identity_role" {
  name               = "${local.application_name}-${local.environment}-test-eks-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.test_eks_pod_identity_assume_role.json
}

# Validates SCP allows eks:CreatePodIdentityAssociation.
resource "aws_eks_pod_identity_association" "test_eks_pod_identity_association" {
  cluster_name    = aws_eks_cluster.test_eks_cluster.name
  namespace       = "default"
  service_account = "default"
  role_arn        = aws_iam_role.test_eks_pod_identity_role.arn
}

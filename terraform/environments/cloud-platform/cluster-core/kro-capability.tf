###############################################################################
# KRO EKS Capability (US-005c / ADR-003)
#
# Enables KRO as an AWS-managed EKS Capability. KRO operates entirely within
# the cluster — the role only establishes trust with the Capabilities service.
###############################################################################

resource "aws_iam_role" "kro_capability" {
  name = "${local.cluster_name}-kro-capability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "capabilities.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = local.tags
}

resource "time_sleep" "kro_role_propagation" {
  depends_on      = [aws_iam_role.kro_capability]
  create_duration = "15s"
}

resource "aws_eks_capability" "kro" {
  cluster_name              = local.cluster_name
  capability_name           = "${local.cluster_name}-kro"
  type                      = "KRO"
  role_arn                  = aws_iam_role.kro_capability.arn
  delete_propagation_policy = "RETAIN"

  tags = local.tags

  depends_on = [time_sleep.kro_role_propagation]
}

###############################################################################
# Grant KRO cluster admin access to create resources from RGDs
###############################################################################

resource "aws_eks_access_policy_association" "kro_admin" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.kro_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_capability.kro]
}

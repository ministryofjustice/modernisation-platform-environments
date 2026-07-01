###############################################################################
# ACK EKS Capability (US-005c)
#
# Enables ACK as an AWS-managed EKS Capability. Deploys all ACK controllers
# (RDS, Secrets Manager, etc.) managed by AWS. No Helm required.
#
# PREREQUISITE: The RDS service-linked role (AWSServiceRoleForRDS) must exist
# in the account before ACK can create RDS instances. Run once per account:
#   aws iam create-service-linked-role --aws-service-name rds.amazonaws.com
###############################################################################

resource "aws_iam_role" "ack_capability" {
  name = "${local.cluster_name}-ack-capability"

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

resource "aws_iam_policy" "ack_capability" {
  name        = "${local.cluster_name}-ack-capability"
  description = "Permissions for ACK EKS Capability — RDS and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:ListTagsForResource",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeOrderableDBInstanceOptions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ack_capability" {
  role       = aws_iam_role.ack_capability.name
  policy_arn = aws_iam_policy.ack_capability.arn
}

resource "time_sleep" "ack_role_propagation" {
  depends_on      = [aws_iam_role_policy_attachment.ack_capability]
  create_duration = "15s"
}

resource "aws_eks_capability" "ack" {
  cluster_name              = local.cluster_name
  capability_name           = "${local.cluster_name}-ack"
  type                      = "ACK"
  role_arn                  = aws_iam_role.ack_capability.arn
  delete_propagation_policy = "RETAIN"

  tags = local.tags

  depends_on = [time_sleep.ack_role_propagation]
}

###############################################################################
# Grant ACK cluster admin access to read Kubernetes Secrets
#
# ACK needs to read Kubernetes Secrets (e.g. master passwords for RDS) from
# application namespaces. The default AmazonEKSACKPolicy doesn't cover this.
###############################################################################

resource "aws_eks_access_policy_association" "ack_admin" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.ack_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_capability.ack]
}

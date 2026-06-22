data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

# IAM role for cert-manager IRSA
resource "aws_iam_role" "cert_manager" {
  name        = "cert-manager-${var.cluster_name}"
  description = "Role for cert-manager to update Route53 DNS records"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")}:sub" : "system:serviceaccount:cert-manager:cert-manager"
          }
        }
      }
    ]
  })
}

# IAM policy for Route53 access
resource "aws_iam_policy" "cert_manager" {
  name        = "cert-manager-route53-${var.cluster_name}"
  description = "Policy for cert-manager to update Route53 records for ACME challenges"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange"
        ]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}

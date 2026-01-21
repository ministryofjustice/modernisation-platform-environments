# IAM role to allow production account to read hosted zones for account delegation
data "aws_iam_policy_document" "cross_account_hosted_zones_assume_role" {
  statement {
    sid    = "AllowProductionAccountAssume"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["cloud-platform-live-production"]}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cross_account_hosted_zones_policy" {
  statement {
    sid    = "ReadRoute53HostedZones"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["non-live-${local.environment}.${local.base_domain}."]
  }
}

resource "aws_iam_role" "cross_account_hosted_zones_read" {
  count              = terraform.workspace != "cloud-platform-non-live-production" ? 1 : 0
  name               = "cross-account-hosted-zones-read"
  description        = "Allows production account to read hosted zones for account delegation NS records"
  assume_role_policy = data.aws_iam_policy_document.cross_account_hosted_zones_assume_role.json
}

resource "aws_iam_role_policy" "cross_account_hosted_zones_read" {
  count  = terraform.workspace != "cloud-platform-non-live-production" ? 1 : 0
  name   = "hosted-zones-read-policy"
  role   = aws_iam_role.cross_account_hosted_zones_read[0].id
  policy = data.aws_iam_policy_document.cross_account_hosted_zones_policy.json
}
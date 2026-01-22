# IAM role to allow production account to read hosted zones for account delegation
data "aws_iam_policy_document" "cross_account_hosted_zones_assume_role" {
  statement {
    sid    = "AllowProductionAccountAssume"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-production"]}:role/github-actions"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cross_account_hosted_zones_policy" {
  statement {
    sid       = "ListAllHostedZones"
    effect    = "Allow"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }

  statement {
    sid    = "ReadSpecificHostedZone"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/${aws_route53_zone.account_zone.zone_id}"]
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


# Policy to allow github-actions role in production to assume cross-account hosted zones read roles
data "aws_iam_policy_document" "github_actions_assume_hosted_zones_role" {
  count = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  statement {
    sid     = "AssumeHostedZonesReadRoles"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-development"]}:role/cross-account-hosted-zones-read",
      "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-test"]}:role/cross-account-hosted-zones-read",
      "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-non-live-preproduction"]}:role/cross-account-hosted-zones-read"
    ]
  }
}

resource "aws_iam_policy" "github_actions_assume_hosted_zones_role" {
  count  = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  name   = "github-actions-assume-hosted-zones-read"
  policy = data.aws_iam_policy_document.github_actions_assume_hosted_zones_role[0].json
}

resource "aws_iam_role_policy_attachment" "github_actions_assume_hosted_zones_role" {
  count      = terraform.workspace == "cloud-platform-non-live-production" ? 1 : 0
  role       = "github-actions"
  policy_arn = aws_iam_policy.github_actions_assume_hosted_zones_role[0].arn
}
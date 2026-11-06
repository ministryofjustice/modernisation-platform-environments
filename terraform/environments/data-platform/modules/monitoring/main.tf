locals {
  role_name = "data-platform-monitoring"
  trusted_role_arns = [
    # Development namespace IRSA role
    "arn:aws:iam::754256621582:role/cloud-platform-irsa-4348d681e9c70290-live",
    # Production namespace IRSA role
    "arn:aws:iam::754256621582:role/cloud-platform-irsa-405b2679c48ef147-live"
  ]
}

module "iam_role" {
  source          = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0
  name            = local.role_name
  use_name_prefix = false

  trust_policy_permissions = {
    TrustedRoles = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = local.trusted_role_arns
      }]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_read_only_access" {
  role       = module.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "amazon_prometheus_query_access" {
  role       = module.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_iam_role_policy_attachment" "aws_xray_read_only_access" {
  role       = module.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = { for k, v in var.additional_policies : k => v }

  role       = module.iam_role.name
  policy_arn = each.value
}

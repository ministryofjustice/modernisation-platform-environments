module "observability_platform_tenant" {

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=fbbe5c8282786bcc0a00c969fe598e14f12eea9b" # v1.2.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "observability_platform_role_grafana_athena_full_access_attachment" {
  role       = "observability-platform"
  policy_arn = "arn:aws:iam::aws:policy/AmazonGrafanaAthenaAccess"
}

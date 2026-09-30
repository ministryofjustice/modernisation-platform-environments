# Account-wide alerting shared by the feasibility apps

module "alerting" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0dcff3f
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alerting?ref=0dcff3f"

  name = local.application_name

  tags = local.tags
}

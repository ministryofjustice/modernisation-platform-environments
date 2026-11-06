# Account-wide alerting shared by the feasibility apps

module "alerting" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/10d2292
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/alerting?ref=10d2292"

  name = local.application_name

  tags = local.tags
}

locals {
  env_ = "${local.environment_shorthand}_"
  cap_dw_tables = local.is-production || local.is-test ? [
    "contact_history",
    "equipment_details",
    "event_history",
    "incident",
    "order_details",
    "services",
    "suspension_of_visits",
    "violations",
    "visit_details"
  ] : []
  am_tables = local.is-production ? [
    "am_contact_history",
    "am_equipment_details",
    "am_incident",
    "am_order_details",
    "am_services",
    "am_visit_details"
  ] : []
}

resource "aws_lakeformation_resource" "data_bucket" {
  arn = module.s3-create-a-derived-table-bucket.bucket.arn
}

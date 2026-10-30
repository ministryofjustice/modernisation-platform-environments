locals {
  resource_name_prefix = "${local.application_name}-${local.component_name}"
  account_id           = data.aws_caller_identity.current.account_id
  region               = data.aws_region.current.region

  # Value of the "source" field on every event published through the API.
  event_source = "${local.application_name}.api"
}

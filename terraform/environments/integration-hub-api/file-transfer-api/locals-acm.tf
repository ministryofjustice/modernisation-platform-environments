locals {
  acm_domains = {
    api = local.is-production ? "api.file-transfer.service.justice.gov.uk" : "api.${local.environment}.file-transfer.service.justice.gov.uk"
  }
}

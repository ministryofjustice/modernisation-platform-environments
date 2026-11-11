locals {
  acm_domains = {
    ftps    = local.is-production == false ? "ftps.${local.environment}.file-transfer.service.justice.gov.uk" : "ftps.file-transfer.service.justice.gov.uk"
    web_app = local.is-production == false ? "web.${local.environment}.file-transfer.service.justice.gov.uk" : "web.file-transfer.service.justice.gov.uk"
  }
}
locals {

  ec2_records = [
    "decisions",
    "asylumsupport.decisions",
    "adminappeals.reports",
    "charity.decisions",
    "claimsmanagement.decisions",
    "consumercreditappeals.decisions",
    "estateagentappeals.decisions",
    "phl.decisions",
    "sscs.venues",
    "siac.decisions",
    "taxandchancery_ut.decisions",
    "tax.decisions"
  ]

  afd_records = [
    "administrativeappeals.decisions",
    "carestandards.decisions",
    "cicap.decisions",
    "employmentappeals.decisions",
    "financeandtax.decisions",
    "immigrationservices.decisions",
    "informationrights.decisions",
    "landregistrationdivision.decisions",
    "landschamber.decisions",
    "transportappeals.decisions"
  ]

  nginx_records = [
    "",
    "adjudicationpanel",
    "charity",
    "consumercreditappeals",
    "estateagentappeals",
    "fhsaa",
    "siac"
  ]

  www_records = [
    "www.adjudicationpanel",
    "www.charity",
    "www.consumercreditappeals",
    "www.estateagentappeals",
    "www.fhsaa",
    "www.siac",
    "www"
  ]

  production_zone_id = data.aws_route53_zone.production_zone.zone_id
}
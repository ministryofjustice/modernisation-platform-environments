moved {
  from = aws_acm_certificate.ftps
  to   = module.acm_ftps.aws_acm_certificate.this[0]
}

moved {
  from = aws_acm_certificate_validation.ftps
  to   = module.acm_ftps.aws_acm_certificate_validation.this[0]
}

moved {
  from = aws_acm_certificate.web_app
  to   = module.acm_web_app.aws_acm_certificate.this[0]
}

moved {
  from = aws_acm_certificate_validation.web_app
  to   = module.acm_web_app.aws_acm_certificate_validation.this[0]
}

# Domain-keyed module instances give each workspace a distinct static move target.
moved {
  from = aws_route53_record.ftps_cert_validation["ftps.development.file-transfer.service.justice.gov.uk"]
  to   = module.acm_ftps_validation["ftps.development.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.ftps_cert_validation["ftps.test.file-transfer.service.justice.gov.uk"]
  to   = module.acm_ftps_validation["ftps.test.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.ftps_cert_validation["ftps.preproduction.file-transfer.service.justice.gov.uk"]
  to   = module.acm_ftps_validation["ftps.preproduction.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.ftps_cert_validation["ftps.file-transfer.service.justice.gov.uk"]
  to   = module.acm_ftps_validation["ftps.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.web_app_cert_validation["web.development.file-transfer.service.justice.gov.uk"]
  to   = module.acm_web_app_validation["web.development.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.web_app_cert_validation["web.test.file-transfer.service.justice.gov.uk"]
  to   = module.acm_web_app_validation["web.test.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.web_app_cert_validation["web.preproduction.file-transfer.service.justice.gov.uk"]
  to   = module.acm_web_app_validation["web.preproduction.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}

moved {
  from = aws_route53_record.web_app_cert_validation["web.file-transfer.service.justice.gov.uk"]
  to   = module.acm_web_app_validation["web.file-transfer.service.justice.gov.uk"].aws_route53_record.validation[0]
}
module "route53_zone" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/route53/aws"
  version = "6.5.0"


  # tflint-ignore: terraform_deprecated_interpolation
  name    = local.environment_configuration.route53_zone
  comment = local.environment_configuration.route53_zone

  records = {
    airflow = {
      name    = "airflow"
      type    = "CNAME"
      ttl     = 300
      records = [data.aws_lb.mwaa_alb.dns_name]
    }
    _amazonses = {
      name    = "_amazonses"
      type    = "TXT"
      ttl     = 600
      records = [aws_ses_domain_identity.main.verification_token]
    }
    "${aws_ses_domain_dkim.main.dkim_tokens[0]}._domainkey" = {
      name    = "${aws_ses_domain_dkim.main.dkim_tokens[0]}._domainkey"
      type    = "CNAME"
      ttl     = 300
      records = ["${aws_ses_domain_dkim.main.dkim_tokens[0]}.dkim.amazonses.com"]
    }
    "${aws_ses_domain_dkim.main.dkim_tokens[1]}._domainkey" = {
      name    = "${aws_ses_domain_dkim.main.dkim_tokens[1]}._domainkey"
      type    = "CNAME"
      ttl     = 300
      records = ["${aws_ses_domain_dkim.main.dkim_tokens[1]}.dkim.amazonses.com"]
    },
    "${aws_ses_domain_dkim.main.dkim_tokens[2]}._domainkey" = {
      name    = "${aws_ses_domain_dkim.main.dkim_tokens[2]}._domainkey"
      type    = "CNAME"
      ttl     = 300
      records = ["${aws_ses_domain_dkim.main.dkim_tokens[2]}.dkim.amazonses.com"]
    }
  }

  tags = local.tags
}


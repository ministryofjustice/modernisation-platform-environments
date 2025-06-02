module "route53_records" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "5.0.0"

  zone_id = module.route53_zones.route53_zone_zone_id[local.environment_configuration.route53_zone]

  records = [
    {
      name    = "airflow"
      type    = "CNAME"
      ttl     = 300
      records = [data.aws_lb.mwaa_alb.dns_name]
    },
    {
      name    = "_amazonses"
      type    = "TXT"
      ttl     = 600
      records = [aws_ses_domain_identity.main.verification_token]
    },
    {
      name    = "${aws_ses_domain_dkim.main.dkim_tokens[0]}._domainkey"
      type    = "CNAME"
      ttl     = 300
      records = ["${aws_ses_domain_dkim.main.dkim_tokens[0]}.dkim.amazonses.com"]
    },
    {
      name    = "${aws_ses_domain_dkim.main.dkim_tokens[1]}._domainkey"
      type    = "CNAME"
      ttl     = 300
      records = ["${aws_ses_domain_dkim.main.dkim_tokens[1]}.dkim.amazonses.com"]
    },
    {
      name    = "${aws_ses_domain_dkim.main.dkim_tokens[2]}._domainkey"
      type    = "CNAME"
      ttl     = 300
      records = ["${aws_ses_domain_dkim.main.dkim_tokens[2]}.dkim.amazonses.com"]
    }
  ]
}

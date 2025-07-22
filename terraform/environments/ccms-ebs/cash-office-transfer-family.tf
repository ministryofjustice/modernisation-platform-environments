/*
Due to what appear to be bugs in the aws_s3control_access_grant and awscc_transfer_web_app
resources. Both of these are created an managed manually until those issues can be ironed out.

What should be working configurations have been added to Terraform and left commented
out in:
- modules/transfer-family/grant.tf
- modules/transfer-family/main.tf

Until those bugs are addressed, the below resources are created manually in PRODUCTION ONLY:
- An S3 Transfer Family Web App, using the role ccms-ebs-cashoffice-transfer (created by this module)
- An S3 grant to s3://laa-ccms-inbound-production-mp/* for the entra/identity centre group
  azure-aws-sso-laa-ccms-ebs-s3-cashoffice (which has the group ID c64272c4-30a1-7039-8ffd-af791143da2e)
- A DNS CNAME for ccms-ebs-upload.laa-production.modernisation-platform.service.justice.gov.uk which maps to
  the S3 Transfer Family Web App
*/

module "transfer_family" {
  count                         = local.is-development ? 1 : 0
  source                        = "./modules/transfer-family"
  aws_account_id                = data.aws_caller_identity.current.account_id
  app_name                      = local.application_name
  bucket_name                   = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  aws_identity_centre_store_arn = local.application_data.accounts[local.environment].cash_office_idp_arn
}

/*
Because of the issues above, the below DNS record relies on a manual input, following the
manual creation of a Web App
*/
resource "aws_route53_record" "transfer_family" {
  count    = local.is-development ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ebs-upload"
  type     = "CNAME"
  ttl      = 300
  records  = [local.application_data.accounts[local.environment].cash_web_app_url]
}

resource "aws_cloudfront_distribution" "transfer_family" {
  enabled         = true
  comment         = "CloudFront Distribution: cashoffice"
  is_ipv6_enabled = false
  http_version    = "http2" # Automatically supports http/2, http/1.1, and http/1.0
  aliases         = ["${aws_route53_record.transfer_family[0].name}.${trim(data.aws_route53_zone.external.name, ".")}"]
  origin {
    domain_name = local.application_data.accounts[local.environment].cash_web_app_url
    origin_id   = "transfer-family"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  default_cache_behavior {
    target_origin_id       = "transfer-family"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    compress = true
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}
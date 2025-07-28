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
The resourced below here are not a good candidate for inclusion in a module as they require creation
AFTER the manual creation of a webapp and the input of the webapps URL
*/
resource "aws_route53_record" "transfer_family" {
  count    = local.is-development ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_data.accounts[local.environment].cash_office_upload_hostname
  type     = "CNAME"
  ttl      = 300
  records  = [aws_cloudfront_distribution.transfer_family.domain_name]
}

/*
Certs need to be created in us-east-1 as they are associated with Cloudfront
*/
resource "aws_acm_certificate" "transfer_family" {
  count                     = local.is-development ? 1 : 0
  provider                  = aws.us-east-1
  domain_name               = trim(data.aws_route53_zone.external.name, ".") #--Remove the trailing dot from the zone name
  subject_alternative_names = [aws_route53_record.transfer_family[0].fqdn]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "transfer_family" {
  count                   = local.is-development ? 1 : 0
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.transfer_family[0].arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_route53_record" "validation" {
  provider = aws.core-vpc
  for_each = local.transfer_family_dvo_map
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_cloudfront_distribution" "transfer_family" {
  count           = local.is-development ? 1 : 0
  enabled         = true
  comment         = "CloudFront Distribution: cashoffice"
  is_ipv6_enabled = false
  http_version    = "http2" # Automatically supports http/2, http/1.1, and http/1.0
  aliases         = ["${local.application_data.accounts[local.environment].cash_office_upload_hostname}.${trim(data.aws_route53_zone.external.name, ".")}"]
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
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate_validation.transfer_family[0].certificate_arn
    ssl_support_method             = "sni-only"
  }
}

/*
Once all resources are created. The Web App must have it's URL manually configured to point to
the newly created DNS record of ccms-file-uploads.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk
*/
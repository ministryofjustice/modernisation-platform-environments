resource "aws_cloudfront_distribution" "tribunals_distribution" {
  #checkov:skip=CKV_AWS_86:"Access logging not required for this distribution"
  #checkov:skip=CKV_AWS_374:"Geo restriction not needed for this public service"
  #checkov:skip=CKV_AWS_305:"Default root object not required as this is an API distribution"
  #checkov:skip=CKV_AWS_310:"Single origin is sufficient for this use case"
  #checkov:skip=CKV2_AWS_47:"Skip Log4j protection as it is handled via WAF"
  #checkov:skip=CKV2_AWS_46:"Origin Access Identity not applicable as origin is ALB, not S3"

  web_acl_id = aws_wafv2_web_acl.tribunals_web_acl.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs-v2/"
  }

  aliases = local.is-production ? concat(local.common_sans, local.cloudfront_sans, ["*.decisions.tribunals.gov.uk"]) : local.nonprod_sans
  origin {
    domain_name = aws_lb.tribunals_lb.dns_name
    origin_id   = "tribunalsOrigin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }

    custom_header {
      name  = "X-Custom-Header"
      value = "tribunals-origin"
    }
  }

  default_cache_behavior {
    target_origin_id = "tribunalsOrigin"

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers_policy.id

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    smooth_streaming       = false

    dynamic "function_association" {
      for_each = local.is-development ? [] : [1]
      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.redirect_function[0].arn
      }
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for tribunals load balancer"
  price_class     = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

// Create a new certificate for the CloudFront distribution because it needs to be in us-east-1
resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us-east-1
  domain_name               = local.is-production ? "*.decisions.tribunals.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = local.is-production ? concat(local.common_sans, local.cloudfront_sans) : local.nonprod_sans

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cloudfront_cert_cname_validation : record.fqdn
  ]
}

// Route53 DNS records for certificate validation
// Don't duplicate the common_sans domains here - already generated in dns_ssl.tf
resource "aws_route53_record" "cloudfront_cert_cname_validation" {
  provider = aws.core-network-services

  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  ttl             = 300
  type            = each.value.type
  zone_id         = local.is-production ? data.aws_route53_zone.production_zone.zone_id : data.aws_route53_zone.network-services.zone_id
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "tribunals_lb_sg_cloudfront" {
  #checkov:skip=CKV_AWS_382:"Load balancer requires unrestricted egress for dynamic port mapping"
  #checkov:skip=CKV2_AWS_5:"Security group is attached to the tribunals load balancer"
  name        = "tribunals-load-balancer-sg-cf"
  description = "control access to the load balancer using cloudfront"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "Allow CloudFront traffic on HTTPS port 443"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "cloudfront_logs" {
  #checkov:skip=CKV2_AWS_62:"Event notifications not required for CloudFront logs bucket"
  #checkov:skip=CKV_AWS_144:"Cross-region replication not required"
  #checkov:skip=CKV_AWS_18:"Access logging not required for CloudFront logs bucket to avoid logging loop"
  bucket = "tribunals-cloudfront-logs-${local.environment}"
}

resource "aws_s3_bucket_versioning" "cloudfront_bucket_versioning" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  #checkov:skip=CKV2_AWS_65:"ACLs are required for CloudFront logging to work"
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
  bucket     = aws_s3_bucket.cloudfront_logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudfront_logs.arn}/cloudfront-logs-v2/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = aws_cloudfront_distribution.tribunals_distribution.arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontLogDeliveryGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudfront_logs.arn
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = "cloudfront-logs/"
    }

    expiration {
      days = 90
    }
  }

  rule {
    id     = "abort-multipart"
    status = "Enabled"

    filter {
      prefix = "" //Empty prefix means apply to all objects
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name    = "tribunals-security-headers-policy"
  comment = "Security headers policy for tribunals CloudFront distribution"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
      override                = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

resource "aws_cloudfront_function" "redirect_function" {
  count   = local.is-development ? 0 : 1
  name    = "tribunals_redirect_function"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<EOF
function handler(event) {
    var request = event.request;
    var host = request.headers.host ? request.headers.host.value : '';
    var uri = request.uri || '/';

    var redirectMap = {
        'siac.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-to-the-special-immigration-appeals-commission',
            pathRedirects: [
                {
                    paths: ['/outcomes2007onwards.htm'],
                    target: 'https://siac.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: ['www.siac.tribunals.gov.uk']
        },
        'fhsaa.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-to-the-primary-health-lists-tribunal',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://phl.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: ['www.fhsaa.tribunals.gov.uk']
        },
        'estateagentappeals.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/estate-agents-appeal-against-a-ban-or-warning-order',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://estateagentappeals.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: ['www.estateagentappeals.tribunals.gov.uk']
        },
        'consumercreditappeals.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/upper-tribunal-tax-and-chancery-chamber',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://consumercreditappeals.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: ['www.consumercreditappeals.tribunals.gov.uk']
        },
        'charity.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-against-a-charity-commission-decision-about-your-charity',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://charity.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: ['www.charity.tribunals.gov.uk']
        },
        'adjudicationpanel.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/hm-courts-and-tribunals-service',
            pathRedirects: [
                {
                    paths: ['/Public', '/Admin', '/Decisions', '/Judgments'],
                    target: 'https://localgovernmentstandards.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: ['www.adjudicationpanel.tribunals.gov.uk']
        },
        'asylum-support-tribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/first-tier-tribunal-asylum-support',
            pathRedirects: [
                {
                    paths: ['/Public', '/admin', '/Judgments', '/decisions.htm'],
                    target: 'https://asylumsupport.decisions.tribunals.gov.uk',
                    exactMatch: false
                },
                {
                    paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://administrativeappeals.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: ['www.asylum-support-tribunal.gov.uk']
        },
        'ahmlr.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/apply-land-registration-tribunal/overview',
            pathRedirects: [
                {
                    paths: ['/public', '/Admin', '/Judgments'],
                    target: 'https://landregistrationdivision.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: ['www.ahmlr.gov.uk']
        },
        'appeals-service.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/social-security-child-support-tribunal',
            pathRedirects: [],
            aliases: ['www.appeals-service.gov.uk']
        },
        'carestandardstribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-to-the-care-standards-tribunal',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/Judgements', '/Admin'],
                    target: 'https://carestandards.decisions.tribunals.gov.uk',
                    exactMatch: false
                },
                {
                    paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://cicap.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: ['www.carestandardstribunal.gov.uk']
        },
        'cicap.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/criminal-injuries-compensation-tribunal',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/DBFiles', '/Admin', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://cicap.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: ['www.cicap.gov.uk']
        },
        'civilappeals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/court-of-appeal-civil-division',
            pathRedirects: [],
            aliases: ['www.civilappeals.gov.uk']
        },
        'cjit.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: ['www.cjit.gov.uk']
        },
        'cjs.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: ['www.cjs.gov.uk']
        },
        'cjsonline.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: ['www.cjsonline.gov.uk']
        },
        'complaints.judicialconduct.gov.uk': {
            defaultRedirect: 'https://www.complaints.judicialconduct.gov.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.complaints.judicialconduct.gov.uk']
        },
        'courtfines.justice.gov.uk': {
            defaultRedirect: 'https://courtfines.direct.gov.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.courtfines.justice.gov.uk']
        },
        'courtfunds.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/contact-court-funds-office',
            pathRedirects: [],
            aliases: ['www.courtfunds.gov.uk']
        },
        'criminal-justice-system.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: ['www.criminal-justice-system.gov.uk']
        },
        'dugganinquest.independent.gov.uk': {
            defaultRedirect: 'https://webarchive.nationalarchives.gov.uk/20151002140003/http://dugganinquest.independent.gov.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.dugganinquest.independent.gov.uk']
        },
        'employmentappeals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/employment-appeal-tribunal',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/Secure'],
                    target: 'https://employmentappeals.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                },
                {
                    paths: ['/Judgments/tips.htm'],
                    target: 'https://employmentappeals.decisions.tribunals.gov.uk/Judgments/tips.htm',
                    exactMatch: true
                },
                {
                    paths: ['/login.aspx'],
                    target: 'https://employmentappeals.decisions.tribunals.gov.uk/secure',
                    exactMatch: true
                },
                {
                    paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://cicap.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.employmentappeals.gov.uk']
        },
        'financeandtaxtribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/collections/upper-tribunal-tax-and-chancery-chamber',
            pathRedirects: [
                {
                    paths: ['/aspx', '/Decisions', '/Admin', '/JudgmentFiles', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://financeandtax.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.financeandtaxtribunals.gov.uk']
        },
        'hillsboroughinquests.independent.gov.uk': {
            defaultRedirect: 'https://webarchive.nationalarchives.gov.uk/20170404105742/https://hillsboroughinquests.independent.gov.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.hillsboroughinquests.independent.gov.uk']
        },
        'immigrationservicestribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-a-decision-on-your-registration-as-an-immigration-adviser',
            pathRedirects: [
                {
                    paths: ['/Aspx', '/Decisions', '/Admin', '/JudgmentFiles'],
                    target: 'https://immigrationservices.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.immigrationservicestribunal.gov.uk']
        },
        'informationtribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/information-rights-appeal-against-the-commissioners-decision',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/DBFiles', '/Admin', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://informationrights.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.informationtribunal.gov.uk']
        },
        'judicialombudsman.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/judicial-appointments-and-conduct-ombudsman$request_uri',
            pathRedirects: [],
            aliases: ['www.judicialombudsman.gov.uk']
        },
        'landstribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/appeal-upper-tribunal-lands',
            pathRedirects: [
                {
                    paths: ['/NEWstyles.css'],
                    target: 'https://landschamber.decisions.tribunals.gov.uk/NEWstyles.css',
                    exactMatch: true
                },
                {
                    paths: ['/Aspx', '/images', '/Decisions', '/Admin', '/JudgmentFiles', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://landschamber.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.landstribunal.gov.uk']
        },
        'obr.co.uk': {
            defaultRedirect: 'https://obr.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.obr.co.uk']
        },
        'osscsc.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/upper-tribunal-administrative-appeals-chamber',
            pathRedirects: [
                {
                    paths: ['/aspx', '/Decisions', '/Admin', '/JudgmentFiles', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://administrativeappeals.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.osscsc.gov.uk']
        },
        'paroleboard.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/parole-board',
            pathRedirects: [],
            aliases: ['www.paroleboard.gov.uk']
        },
        'sendmoneytoaprisoner.justice.gov.uk': {
            defaultRedirect: 'https://sendmoneytoaprisoner.service.justice.gov.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.sendmoneytoaprisoner.justice.gov.uk']
        },
        'transporttribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/approved-driving-instructors-appeal-a-decision-by-the-registrar',
            pathRedirects: [
                {
                    paths: ['/Aspx', '/images', '/DBFiles', '/Admin', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://transportappeals.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: ['www.transporttribunal.gov.uk']
        },
        'victiminformationservice.org.uk': {
            defaultRedirect: 'https://victimsinformationservice.org.uk$request_uri',
            pathRedirects: [],
            aliases: ['www.victiminformationservice.org.uk']
        },
        'yjbpublications.justice.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/publications?departments[]=youth-justice-board-for-england-and-wales',
            pathRedirects: [],
            aliases: ['www.yjbpublications.justice.gov.uk']
        }
    };

    // Find matching config, checking aliases
    var redirectConfig = null;
    for (var domain in redirectMap) {
        if (host === domain || (redirectMap[domain].aliases && redirectMap[domain].aliases.includes(host))) {
            redirectConfig = redirectMap[domain];
            break;
        }
    }

    if (!redirectConfig) {
        return request; // Pass through for unsupported domains
    }

    for (const pathConfig of redirectConfig.pathRedirects) {
        for (const path of pathConfig.paths) {
            const isMatch = pathConfig.exactMatch
                ? uri.toLowerCase() === path.toLowerCase()
                : (path.startsWith('.*\\.') ? new RegExp(path, 'i').test(uri) : uri.toLowerCase().startsWith(path.toLowerCase()));
            if (isMatch) {
                const redirectUrl = pathConfig.exactMatch
                    ? pathConfig.target
                    : pathConfig.target.includes('$request_uri')
                        ? pathConfig.target.replace('$request_uri', uri)
                        : pathConfig.target + uri;
                return {
                    statusCode: 301,
                    statusDescription: 'Moved Permanently',
                    headers: {
                        'location': { value: redirectUrl }
                    }
                };
            }
        }
    }

    const defaultRedirectUrl = redirectConfig.defaultRedirect.endsWith('$request_uri')
        ? redirectConfig.defaultRedirect.replace('$request_uri', uri)
        : redirectConfig.defaultRedirect;
    return {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            'location': { value: defaultRedirectUrl }
        }
    };
  }
  EOF
}

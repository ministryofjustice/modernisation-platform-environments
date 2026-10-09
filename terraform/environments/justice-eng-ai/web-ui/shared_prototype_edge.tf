locals {
  prototype_domain_name   = "ai-prototype.modernisation-platform.service.justice.gov.uk"
  prototype_bucket_prefix = "justice-eng-ai-prototypes"
  prototype_edge_enabled = local.is-production
}

resource "aws_acm_certificate" "prototypes" {
  count = local.prototype_edge_enabled ? 1 : 0

  provider                  = aws.us-east-1
  domain_name               = local.prototype_domain_name
  subject_alternative_names = ["*.${local.prototype_domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "prototype_certificate_validation" {
  provider = aws.core-network-services
  for_each = local.prototype_edge_enabled ? toset([local.prototype_domain_name]) : toset([])

  zone_id         = data.aws_route53_zone.network-services.zone_id
  name = one([
    for option in aws_acm_certificate.prototypes[0].domain_validation_options :
    option.resource_record_name if option.domain_name == each.key
  ])
  type = one([
    for option in aws_acm_certificate.prototypes[0].domain_validation_options :
    option.resource_record_type if option.domain_name == each.key
  ])
  ttl             = 60
  records = [one([
    for option in aws_acm_certificate.prototypes[0].domain_validation_options :
    option.resource_record_value if option.domain_name == each.key
  ])]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "prototypes" {
  count = local.prototype_edge_enabled ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.prototypes[0].arn
  validation_record_fqdns = [for record in aws_route53_record.prototype_certificate_validation : record.fqdn]
}

module "shared-prototype-edge" {
  count  = local.prototype_edge_enabled ? 1 : 0
  source = "./shared-prototype-edge"

  providers = {
    aws                       = aws
    aws.us_east_1             = aws.us-east-1
    aws.core_network_services = aws.core-network-services
  }

  configuration = {
    domain_name        = local.prototype_domain_name
    hosted_zone_id     = data.aws_route53_zone.network-services.zone_id
    certificate_arn    = aws_acm_certificate_validation.prototypes[0].certificate_arn
    bucket_prefix      = local.prototype_bucket_prefix
    allowed_ipv4_cidrs = toset(var.allowed_ingress_cidrs)
  }
  tags = local.tags
}

data "aws_iam_policy_document" "prototype_publisher_trust" {
  count = local.prototype_edge_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["justice-eng-ai-development"]}:role/ai-prototype-deployment-publisher"
      ]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["prototype-id"]
    }
    condition {
      test     = "Null"
      variable = "aws:RequestTag/prototype-id"
      values   = ["false"]
    }
  }
}

resource "aws_iam_role" "prototype_publisher" {
  count              = local.prototype_edge_enabled ? 1 : 0
  name               = "ai-prototype-shared-edge-publisher"
  assume_role_policy = data.aws_iam_policy_document.prototype_publisher_trust[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "prototype_publisher" {
  count = local.prototype_edge_enabled ? 1 : 0

  statement {
    sid       = "ListOnlyPrototypePrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${module.shared-prototype-edge[0].hosting.bucket_name}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["&{aws:PrincipalTag/prototype-id}/", "&{aws:PrincipalTag/prototype-id}/*"]
    }
  }

  statement {
    sid       = "PublishToPrototypePrefix"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
    resources = ["${module.shared-prototype-edge[0].hosting.bucket_arn}/&{aws:PrincipalTag/prototype-id}/*"]
  }

  statement {
    sid       = "RegisterPrototypeHostname"
    effect    = "Allow"
    actions   = ["cloudfront-keyvaluestore:DescribeKeyValueStore", "cloudfront-keyvaluestore:PutKey"]
    resources = [module.shared-prototype-edge[0].hosting.key_value_store_arn]
  }

  statement {
    sid       = "ReadPublisherConfiguration"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.prototype_publisher_config[0].arn]
  }

  statement {
    sid       = "InvalidatePrototypePrefix"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [module.shared-prototype-edge[0].hosting.distribution_arn]
  }
}

resource "aws_iam_role_policy" "prototype_publisher" {
  count  = local.prototype_edge_enabled ? 1 : 0
  name   = "publish-ai-prototypes"
  role   = aws_iam_role.prototype_publisher[0].id
  policy = data.aws_iam_policy_document.prototype_publisher[0].json
}

resource "aws_ssm_parameter" "prototype_publisher_config" {
  count = local.prototype_edge_enabled ? 1 : 0

  name        = "/justice-eng-ai/shared-prototype-edge/publisher-config"
  description = "Non-secret shared edge values read by the static prototype publisher."
  type        = "String"
  value = jsonencode({
    bucket_name           = module.shared-prototype-edge[0].hosting.bucket_name
    domain_name           = module.shared-prototype-edge[0].hosting.domain_name
    distribution_id       = module.shared-prototype-edge[0].hosting.distribution_id
    key_value_store_arn   = module.shared-prototype-edge[0].hosting.key_value_store_arn
  })
  tags = local.tags
}

output "shared_prototype_edge" {
  description = "Shared CloudFront and WAF hosting details; only populated in the production workspace."
  value       = local.prototype_edge_enabled ? module.shared-prototype-edge[0].hosting : null
}

output "shared_prototype_publisher_role_arn" {
  description = "Role assumed by the development prototype deployment workflow to publish a single registered prototype."
  value       = local.prototype_edge_enabled ? aws_iam_role.prototype_publisher[0].arn : null
}
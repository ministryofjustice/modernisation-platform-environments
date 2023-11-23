resource "aws_iam_role" "os_access_role_logs" {
  name               = "opensearch-access-role-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_logs.json
  managed_policy_arns = [
    aws_iam_policy.os_access_policy_logs.arn,
  ]
}

resource "aws_iam_policy" "os_access_policy_logs" {
  name = "opensearch-access-policy-app-logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["es:*"]
        Effect = "Allow"
        Resource = [
          "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.logs_domain}/*"
        ]
      },
    ]
  })
}

resource "aws_kms_key" "logs" {
  description                        = "Used for OpenSearch: logs-observability-platform"
  key_usage                          = "ENCRYPT_DECRYPT"
  bypass_policy_lockout_safety_check = false
  deletion_window_in_days            = 30
  is_enabled                         = true
  enable_key_rotation                = false
  multi_region                       = false
}

// TODO: add vanity url later
# add vanity url to cluster 
# resource "aws_route53_record" "opensearch_custom_domain" {
#   zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id // TODO: update this
#   name    = "logs"
#   type    = "CNAME"
#   ttl     = 600 # 10 mins

#   records = [aws_opensearch_domain.logs.endpoint]
# }

# # needed for load balancer cert
# module "acm_logs" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 4.0"

#   domain_name = "logs.${data.aws_route53_zone.cloud_platform_justice_gov_uk.name}" // TODO: updates this
#   zone_id     = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id        // TODO: update this

#   wait_for_validation = false # for use in an automated pipeline set false to avoid waiting for validation to complete or error after a 45 minute timeout.

#   tags = {
#     Domain = local.logs_domain
#   }
# }


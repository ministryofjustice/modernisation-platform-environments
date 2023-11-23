# data "aws_route53_zone" "cloud_platform_justice_gov_uk" { // TODO: update this
#   name = "cloud-platform.service.justice.gov.uk."
# }

data "aws_iam_policy_document" "assume_role_policy_logs" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "es:Describe*",
      "es:List*",
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpPatch"
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.logs_domain}/*",
      "arn:aws:es:eu-west-2:754256621582:domain/${local.logs_domain}/*", // TODO: update these data blocks
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

data "http" "saml_metadata_logs" {
  url    = "https://${var.auth0_tenant_domain}/samlp/metadata/${auth0_client.opensearch_logs.client_id}"
  method = "GET"
}


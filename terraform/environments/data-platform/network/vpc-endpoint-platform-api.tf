/*
  Interface endpoint for the JDP Platform API, a private API Gateway REST API in the
  matching data-platform-governance account (ministryofjustice/data-platform#1060).

  - Private DNS is off. With it on, this VPC could no longer reach any public API Gateway
    API. Callers use the API-specific hostname instead:
    https://<api-id>-<vpce-id>.execute-api.eu-west-2.amazonaws.com
  - It has its own security group, allowing HTTPS only from the private subnets, where the
    cluster's nodes and pods run.
  - The endpoint policy allows calls only to APIs in the matching data-platform-governance
    account. The API's own resource policy then admits only listed endpoints.
*/

locals {
  platform_api_account_id = local.environment_management.account_ids["data-platform-governance-${local.environment}"]
  platform_api_subnets    = ["private-a", "private-b", "private-c"]
}

resource "aws_security_group" "platform_api_endpoint" {
  name_prefix = "${local.application_name}-${local.environment}-platform-api-endpoint-"
  description = "JDP Platform API VPC endpoint (data-platform#1060)"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.application_name}-${local.environment}-platform-api-endpoint" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "platform_api_endpoint_https" {
  for_each = toset(local.platform_api_subnets)

  security_group_id = aws_security_group.platform_api_endpoint.id
  description       = "HTTPS from ${each.key}"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.subnets[each.key].cidr_block
}

data "aws_iam_policy_document" "platform_api_endpoint" {
  statement {
    sid       = "InvokeJdpPlatformApiOnly"
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.region}:${local.platform_api_account_id}:*/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_vpc_endpoint" "platform_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false
  subnet_ids          = [for subnet in local.platform_api_subnets : aws_subnet.main[subnet].id]
  security_group_ids  = [aws_security_group.platform_api_endpoint.id]
  policy              = data.aws_iam_policy_document.platform_api_endpoint.json

  tags = { Name = "${local.application_name}-${local.environment}-platform-api" }
}

output "platform_api_vpc_endpoint_id" {
  description = "Add this to the JDP Platform API's allowed VPC endpoint list (data-platform#1060)"
  value       = aws_vpc_endpoint.platform_api.id
}

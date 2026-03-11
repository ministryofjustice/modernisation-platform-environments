resource "aws_iam_role" "ssogen_lambda_role" {
  count = local.is-development || local.is-test ? 1 : 0
  name  = "${local.application_name_ssogen}-${local.environment}-dns-failover-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  tags = merge(local.tags, {
    Name = "${local.application_name_ssogen}-${local.environment}-lambda_cloudwatch_sns_role"
  })
}

resource "aws_iam_role_policy" "ssogen_lambda_dns_failover_policy" {
  count = local.is-development || local.is-test ? 1 : 0
  name  = "${local.application_name_ssogen}-${local.environment}-dns-failover-lambda-policy"
  role  = aws_iam_role.ssogen_lambda_role[count.index].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = [aws_kms_key.ssogen_kms_key.arn]
      }
    ]
  })
}

# resource "aws_iam_role_policy_attachment" "ssogen_lambda_attach" {
#   count                        = local.is-development || local.is-test ? 1 : 0
#   role       = aws_iam_role.ssogen_lambda_role[count.index].name
#   policy_arn = aws_iam_policy.ssogen_lambda_policy[count.index].arn
# }

# Empty SG shell (no inline rules)
resource "aws_security_group" "ssogen_lambda_sg" {
  count       = local.is-development || local.is-test ? 1 : 0
  name        = "lambda-dns-failover-sg"
  description = "Egress to Route53 over 443 and to WebLogic targets on app port"
  vpc_id      = data.aws_vpc.shared.id
}

# Egress: HTTPS to the internet (Route 53 API via NAT)
resource "aws_vpc_security_group_egress_rule" "ssogen_lambda_https_out" {
  count             = local.is-development || local.is-test ? 1 : 0
  security_group_id = aws_security_group.ssogen_lambda_sg[count.index].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTPS to AWS APIs (requires NAT if in private subnets)"
}

# OPTIONAL & preferred: Egress only to the target instances' SG on the app port
# Replace aws_security_group.targets.id with your EC2s' SG ID.
# resource "aws_vpc_security_group_egress_rule" "lambda_to_app_sg" {
#   security_group_id            = aws_security_group.lambda_sg.id
#   ip_protocol                  = "tcp"
#   from_port                    = 4443
#   to_port                      = 4443
#   referenced_security_group_id = aws_security_group.ssogen_sg[count.index].id
#   description                  = "Allow health checks to the app port of targets"
# }

data "archive_file" "ssogen_lambda_zip" {
  count       = local.is-development || local.is-test ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ssogen_admin_failover"
  output_path = "${path.module}/lambda/ssogen_admin_failover.zip"
}

resource "aws_lambda_function" "ssogen_lambda_dns_admin_failover" {
  filename         = data.archive_file.ssogen_lambda_zip.output_path
  source_code_hash = base64sha256(join("", local.lambda_source_hashes_ssogen_admin_failover))
  function_name    = "${local.application_name_ssogen}-${local.environment}-dns-failover"
  role             = aws_iam_role.ssogen_lambda_role[count.index].arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  publish          = true

  vpc_config {
    subnet_ids         = data.aws_subnets.shared_private.ids
    security_group_ids = [aws_security_group.ssogen_lambda_sg.id]
  }

  environment {
    variables = {
      PRIMARY_IP     = data.aws_instance.ssogen_primary_details[count.index].private_ip
      SECONDARY_IP   = data.aws_instance.ssogen_secondary_details[count.index].private_ip
      PORT           = local.application_data.accounts[local.environment].tg_ssogen_admin_port
      HOSTED_ZONE_ID = data.aws_route53_zone.external.zone_id
      RECORD_NAME    = aws_route53_record.ssogen_admin_primary.name
    }
  }
}

# resource "aws_cloudwatch_event_rule" "lambda_interval" {
#   name                = "dns-failover-schedule"
#   schedule_expression = "rate(30 seconds)"
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.lambda_interval.name
#   target_id = "dns-failover-check"
#   arn       = aws_lambda_function.dns_failover.arn
# }

resource "aws_lambda_permission" "lambda_allow_events" {
  statement_id  = "AllowExecutionFromEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ssogen_lambda_dns_admin_failover.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ssogen_admin_dns_flip_topic.arn
}

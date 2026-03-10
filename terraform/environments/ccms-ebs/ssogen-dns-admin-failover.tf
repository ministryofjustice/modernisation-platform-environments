# resource "aws_iam_role" "ssogen_lambda_role" {
#   count = local.is-development || local.is-test ? 1 : 0
#   name = "dns-failover-lambda-role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Action": "sts:AssumeRole",
#     "Principal": {"Service": "lambda.amazonaws.com"},
#     "Effect": "Allow"
#   }]
# }
# EOF
# }

# resource "aws_iam_policy" "ssogen_lambda_policy" {
#   count                        = local.is-development || local.is-test ? 1 : 0
#   name = "dns-failover-lambda-policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:*"
#         ],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "route53:ChangeResourceRecordSets",
#           "route53:ListHostedZones",
#           "route53:ListResourceRecordSets"
#         ],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:CreateNetworkInterface",
#           "ec2:DeleteNetworkInterface",
#           "ec2:DescribeInstances"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssogen_lambda_attach" {
#   count                        = local.is-development || local.is-test ? 1 : 0
#   role       = aws_iam_role.ssogen_lambda_role[count.index].name
#   policy_arn = aws_iam_policy.ssogen_lambda_policy[count.index].arn
# }

# # Empty SG shell (no inline rules)
# resource "aws_security_group" "ssogen_lambda_sg" {
#   count                        = local.is-development || local.is-test ? 1 : 0
#   name        = "lambda-failover-sg"
#   description = "Egress to Route53 over 443 and to WebLogic targets on app port"
#   vpc_id      = data.aws_vpc.shared.id
# }

# # Egress: HTTPS to the internet (Route 53 API via NAT)
# resource "aws_vpc_security_group_egress_rule" "ssogen_lambda_https_out" {
#   security_group_id = aws_security_group.ssogen_lambda_sg[count.index].id
#   ip_protocol       = "tcp"
#   from_port         = 443
#   to_port           = 443
#   cidr_ipv4         = "0.0.0.0/0"
#   description       = "Allow HTTPS to AWS APIs (requires NAT if in private subnets)"
# }

# # OPTIONAL & preferred: Egress only to the target instances' SG on the app port
# # Replace aws_security_group.targets.id with your EC2s' SG ID.
# resource "aws_vpc_security_group_egress_rule" "lambda_to_app_sg" {
#   security_group_id            = aws_security_group.lambda_sg.id
#   ip_protocol                  = "tcp"
#   from_port                    = 4443
#   to_port                      = 4443
#   referenced_security_group_id = aws_security_group.ssogen_sg[count.index].id
#   description                  = "Allow health checks to the app port of targets"
# }

# resource "aws_lambda_function" "dns_failover" {
#   function_name = "dns-failover-lambda"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.9"

#   filename = "${path.module}/lambda.zip"

#   vpc_config {
#     subnet_ids         = var.lambda_subnets
#     security_group_ids = [aws_security_group.lambda_sg.id]
#   }

#   environment {
#     variables = {
#       PRIMARY_IP     = var.primary_ip
#       SECONDARY_IP   = var.secondary_ip
#       PORT           = var.port
#       HOSTED_ZONE_ID = var.zone_id
#       RECORD_NAME    = var.record_name
#     }
#   }
# }

# resource "aws_lambda_function" "dns_failover" {
#   function_name = "dns-failover-lambda"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.9"

#   filename = "${path.module}/lambda.zip"

#   vpc_config {
#     subnet_ids         = var.lambda_subnets
#     security_group_ids = [aws_security_group.lambda_sg.id]
#   }

#   environment {
#     variables = {
#       PRIMARY_IP     = var.primary_ip
#       SECONDARY_IP   = var.secondary_ip
#       PORT           = var.port
#       HOSTED_ZONE_ID = var.zone_id
#       RECORD_NAME    = var.record_name
#     }
#   }
# }

# resource "aws_cloudwatch_event_rule" "lambda_interval" {
#   name                = "dns-failover-schedule"
#   schedule_expression = "rate(30 seconds)"
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.lambda_interval.name
#   target_id = "dns-failover-check"
#   arn       = aws_lambda_function.dns_failover.arn
# }

# resource "aws_lambda_permission" "lambda_allow_events" {
#   statement_id  = "AllowExecutionFromEvents"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.dns_failover.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.lambda_interval.arn
# }
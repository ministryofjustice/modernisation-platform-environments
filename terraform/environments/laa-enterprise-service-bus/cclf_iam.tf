resource "aws_iam_role" "cclf_lambda_role" {
  name = "${local.application_name}-cclf-lambda-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-cclf-lambda-role"
    }
  )
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# resource "aws_iam_policy" "cclf_lambda_role_policy" {
#   name = "${local.application_name}-cclf-lambda-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "elasticloadbalancing:DeregisterInstancesFromLoadBalancer"
#         ]
#         Resource = "*"
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cclf_lambda_role_policy_attachment" {
#   role       = aws_iam_role.cclf_lambda_role.name
#   policy_arn = aws_iam_policy.cclf_lambda_role_policy.arn
# }
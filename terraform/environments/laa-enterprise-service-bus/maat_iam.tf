# resource "aws_iam_role" "maat_lambda_role" {
#   name = "${local.application_name}-maat-lambda-role"
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-maat-lambda-role"
#     }
#   )
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "maat_lambda_role_policy" {
#   name = "${local.application_name}-maat-lambda-policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogGroup"
#         ],
#         Resource = "arn:aws:logs:*:*:*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "maat_lambda_role_policy_attachment" {
#   role       = aws_iam_role.maat_lambda_role.name
#   policy_arn = aws_iam_policy.maat_lambda_role_policy.arn
# }
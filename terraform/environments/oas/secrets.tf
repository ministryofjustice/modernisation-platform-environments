#### This file can be used to store secrets specific to the member account ####

resource "aws_lambda_function" "secrets" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename        = "${path.module}/secret_rotation.zip"
  function_name   = local.application_data.accounts[local.environment].lambda_function_name
  role            = aws_iam_role.iam_for_lambda.arn
  # role_arn      = aws_iam_role.lambda.arn
  handler         = local.application_data.accounts[local.environment].lambda_handler
  timeout         = 30
  runtime         = local.application_data.accounts[local.environment].lambda_runtime
  # source_code_hash = data.archive_file.lambda.output_base64sha256

  # module_tags = {
  #   Environment = "development"
  # }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/secret_rotation.py"
  output_path = "${path.module}/secret_rotation.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# resource "aws_iam_instance_profile" "lambda_profile" {
#   name = "${var.app_name}-lambda-profile"
#   role = aws_iam_role.iam_for_lambda.name
#   tags = merge(
#     var.tags_common,
#     {
#       Name = "${var.app_name}-lambda-profile"
#     }
#   )
# }

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "iam_lambda_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "iam_lambda_policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup"
            ],
            "Resource": "!Sub 'arn:aws:logs:${AWS::Region}:${pFunctionAWSaccount}:*'"
        }
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "!Sub 'arn:aws:logs:${AWS::Region}:${pFunctionAWSaccount}:log-group:/aws/lambda/${pFunctionName}:*'"
        }
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:CreateSecret",
                "secretsmanager:ListSecrets",
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:PutSecretValue",
                "secretsmanager:UpdateSecretVersionStage",
                "secretsmanager:GetRandomPassword",
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        }
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetRandomPassword"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_lambda_policy.arn
}
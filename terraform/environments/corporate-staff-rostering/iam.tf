# Create user for MGN
#tfsec:ignore:aws-iam-no-user-attached-policies
#tfsec:ignore:AWS273
resource "aws_iam_user" "mgn_user" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also set to ignore"
  name = "MGN-Test"
  tags = local.tags
}
#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user_policy_attachment" "mgn_attach_policy_migration" {
  #tfsec:ignore:aws-iam-no-user-attached-policies "This is a short lived user, so allowing IAM policies attached directly to a user."
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationMigrationAgentInstallationPolicy"
}

#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user_policy_attachment" "mgn_attach_policy_discovery" {
  #tfsec:ignore:aws-iam-no-user-attached-policies "This is a short lived user, so allowing IAM policies attached directly to a user."
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationDiscoveryAgentAccess"
}

resource "aws_iam_user_policy_attachment" "mgn_attach_policy_service_access" {
  #tfsec:ignore:aws-iam-no-user-attached-policies "This is a short lived user, so allowing IAM policies attached directly to a user."
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationDiscoveryServiceFullAccess"
}

resource "aws_iam_user_policy_attachment" "mgn_attach_policy_migrationhub_access" {
  #tfsec:ignore:aws-iam-no-user-attached-policies "This is a short lived user, so allowing IAM policies attached directly to a user."
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSMigrationHubFullAccess"
}

resource "aws_iam_user_policy_attachment" "mgn_attach_policy_app_migrationfull_access" {
  #tfsec:ignore:aws-iam-no-user-attached-policies "This is a short lived user, so allowing IAM policies attached directly to a user."
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationMigrationFullAccess"
}

# AD clean up lambda IAM resources
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-ad-role" {
  name  = "LambdaFunctionADObjectCleanUp"
  tags  = local.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# To be built after first apply
# resource "aws_iam_policy" "lambda_eventbridge_policy" {
#   name        = "ADLambdaEventBridgePolicy"
#   description = "Policy allowing Lambda to be triggered by EventBridge"

#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": "lambda:InvokeFunction",
#         "Resource": aws_lambda_function.ad-clean-up-lambda.arn
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "lambda-vpc-attachment" {
  role       = aws_iam_role.lambda-ad-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager" {
  role       = aws_iam_role.lambda-ad-role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# To be built after first apply
# resource "aws_iam_role_policy_attachment" "lambda_eventbridge" {
#   role       = aws_iam_role.lambda-ad-role.name
#   policy_arn = aws_iam_policy.lambda_eventbridge_policy.arn
# }

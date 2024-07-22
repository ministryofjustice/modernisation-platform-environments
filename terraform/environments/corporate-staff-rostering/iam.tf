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
  name = "LambdaFunctionADObjectCleanUp"
  tags = local.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_policy" "lambda-ad-policy" {
  # checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  # checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  name        = "LambdaADObjectCleanUpPolicy"
  description = "Policy to grant AD lambda function VPC access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:Describe*",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy" "HmppsDomainSecrets" {
  name = "HmppsDomainSecretsPolicy"
}

data "aws_iam_policy" "BusinessUnitKmsCmk" {
  name = "BusinessUnitKmsCmkPolicy"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda-ad-role.name
  policy_arn = data.aws_iam_policy.HmppsDomainSecrets.arn
}

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  role       = aws_iam_role.lambda-ad-role.name
  policy_arn = data.aws_iam_policy.BusinessUnitKmsCmk.arn
}

resource "aws_iam_role_policy_attachment" "lambda-ad-policy-attachment" {
  role       = aws_iam_role.lambda-ad-role.name
  policy_arn = aws_iam_policy.lambda-ad-policy.arn
}





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
}q

resource "aws_iam_role" "lambda-ad-role" {
  count = local.environment == "test" ? 1 : 0 # temporary
  name  = "LambdaFunctionADObjectCleanUp"
  tags  = local.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda-vpc-attachment" {
  count      = local.environment == "test" ? 1 : 0 # temporary
  role       = aws_iam_role.lambda-ad-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

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

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager" {
  count      = local.environment == "test" ? 1 : 0 # temporary
  role       = aws_iam_role.lambda-ad-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}


####################################################
# IAM Policy, Role, Profile for SSM, S3 & Cloudwatch
####################################################

# IAM EC2 Policy with Assume Role 

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create EC2 IAM Role
resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2-iam-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Create EC2 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}

# Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "ec2_attach1" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ec2_attach2" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "production-s3-access" {
  count      = local.is-production == false ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "Prod-s3-access-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = aws_iam_policy.production-s3-access[0].arn
}

resource "aws_iam_policy_attachment" "CloudWatchAgentAdminPolicy" {
  count      = local.is-production == true ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "CloudWatchAgentAdminPolicy-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_policy_attachment" "CloudWatchAgentServerPolicy" {
  count      = local.is-production == true ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "CloudWatchAgentServerPolicy-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#####################################
# IAM Policy for Prodcution S3 access
#####################################

resource "aws_iam_policy" "production-s3-access" {
  count      = local.is-production == false ? 1 : 0
  name        = "production-s3-access"
  path        = "/"
  description = "production-s3-access"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "s3:ListBucket",
    "Effect": "Allow",
    "Resource": [
       "arn:aws:s3:::moj-scripts",
       "arn:aws:s3:::moj-scripts/*",
       "arn:aws:s3:::moj-release-management",
       "arn:aws:s3:::moj-release-management/*"
    ]
  }]
})
}

#################################
# IAM Role for SSM Patch Manager
#################################

resource "aws_iam_role" "patching_role" {
  name = "maintenance_window_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach necessary policies to the Patching role
resource "aws_iam_role_policy_attachment" "maintenance_window_task_policy_attachment" {
  role       = aws_iam_role.patching_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

################################
# IAM Role & Policy for Lambda
###############################

resource "aws_iam_role" "lambda_role" {
count      = local.is-production == true ? 1 : 0
name   = "PPUD_Lambda_Function_Role"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_policy" "iam_policy_for_lambda" {
 count      = local.is-production == true ? 1 : 0
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*"
    },
   {
     "Effect": "Allow",
     "Action": [
        "ec2:Start*",
        "ec2:Stop*"
      ],
      "Resource": "*"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_to_lambda_role" {
 count      = local.is-production == true ? 1 : 0
 role        = aws_iam_role.lambda_role[0].name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda[0].arn
}

## SNS IAM Policies
data "aws_iam_policy_document" "sns_topic_policy_ec2cw" {
  policy_id = "SnsTopicId"
  statement {
    sid = "statement1"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    resources = [
      aws_sns_topic.cw_alerts.arn
    ]
  }
}
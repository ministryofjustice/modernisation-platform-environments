
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
  count       = local.is-production == false ? 1 : 0
  name        = "production-s3-access"
  path        = "/"
  description = "production-s3-access"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Action" : "s3:ListBucket",
      "Effect" : "Allow",
      "Resource" : [
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
################################

resource "aws_iam_role" "lambda_role" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role"
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
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = <<EOF
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
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda[0].arn
}

################################################
# IAM Role & Policy for Lambda Alarm Suppression
################################################

resource "aws_iam_role" "lambda_role_alarm_suppression" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Alarm_Suppression"
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

resource "aws_iam_policy" "iam_policy_for_lambda_alarm_suppression" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_alarm_suppression"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role alarm suppression"
  policy      = <<EOF
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
        "cloudwatch:DisableAlarmActions",
        "cloudwatch:EnableAlarmActions"
      ],
      "Resource": [
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-014bce95a85aaeede",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-00cbccc46d25e77c6",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-0dba6054c0f5f7a11",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-0b5ef7cb90938fb82",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-04bbb6312b86648be",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-00413756d2dfcf6d2",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-080498c4c9d25e6bd",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-i-029d2b17679dab982",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-70%-i-029d2b17679dab982",
      "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:CPU-High-90%-i-029d2b17679dab982"
      ]
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_alarm_suppression_to_lambda_role_alarm_suppression" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_alarm_suppression[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_alarm_suppression[0].arn
}

###########################################################
# IAM Role & Policy for Cloudwatch - Lambda Functions - DEV
###########################################################

resource "aws_iam_role" "lambda_role_cloudwatch_invoke_lambda_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Cloudwatch_Invoke_Lambda_Dev"
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

resource "aws_iam_policy" "iam_policy_for_lambda_cloudwatch_invoke_lambda_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_cloudwatch_invoke_lambda_dev"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role cloudwatch invoke lambda development"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ec2:DescribeInstances",
        "lambda:InvokeAsync",
        "lambda:InvokeFunction"
      ],
      "Resource": [
      "arn:aws:ssm:eu-west-2:075585660276:*",
      "arn:aws:cloudwatch:eu-west-2:075585660276:*",
      "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript",
      "arn:aws:lambda:eu-west-2:075585660276:*",
      "arn:aws:ec2:eu-west-2:075585660276:*"
      ]
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_cloudwatch_invoke_lambda_dev[0].arn
}

##########################################################
# IAM Role & Policy for Lambda Terminate CPU Process - UAT
##########################################################

resource "aws_iam_role" "lambda_role_cloudwatch_invoke_lambda_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Cloudwatch_Invoke_Lambda_UAT"
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

resource "aws_iam_policy" "iam_policy_for_lambda_cloudwatch_invoke_lambda_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_cloudwatch_invoke_lambda_uat"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role cloudwatch invoke lambda uat"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ec2:DescribeInstances",
        "lambda:InvokeAsync",
        "lambda:InvokeFunction"
      ],
      "Resource": [
      "arn:aws:ssm:eu-west-2:172753231260:*",
      "arn:aws:cloudwatch:eu-west-2:172753231260:*",
      "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript",
      "arn:aws:lambda:eu-west-2:172753231260:*",
      "arn:aws:ec2:eu-west-2:172753231260:*"
      ]
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_cloudwatch_invoke_lambda_uat[0].arn
}

###########################################################
# IAM Role & Policy for Lambda Terminate CPU Process - PROD
###########################################################

resource "aws_iam_role" "lambda_role_cloudwatch_invoke_lambda_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Cloudwatch_Invoke_Lambda_PROD"
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

resource "aws_iam_policy" "iam_policy_for_lambda_cloudwatch_invoke_lambda_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_cloudwatch_invoke_lambda_prod"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role cloudwatch invoke lambda prod"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ec2:DescribeInstances",
        "lambda:InvokeAsync",
        "lambda:InvokeFunction"
      ],
      "Resource": [
      "arn:aws:ssm:eu-west-2:817985104434:*",
      "arn:aws:cloudwatch:eu-west-2:817985104434:*",
      "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript",
      "arn:aws:lambda:eu-west-2:817985104434:*",
      "arn:aws:ec2:eu-west-2:817985104434:*"
      ]
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_cloudwatch_invoke_lambda_prod[0].arn
}

###########################################################
# IAM Role & Policy for Lambda Certificate Expiration - DEV
###########################################################

resource "aws_iam_role" "lambda_role_certificate_expiry_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Certificate_Expiry_Dev"
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

resource "aws_iam_policy" "iam_policy_for_lambda_certificate_expiry_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_certificate_expiry_dev"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role certificate expiry development"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid":"LambdaCertificateExpiryPolicy1",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-2:075585660276:*"
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:075585660276:log-group:/aws/lambda/handle-expiring-certificates:*"
            ]
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy3",
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:GetCertificate",
                "acm:ListCertificates",
                "acm:ListTagsForCertificate"
            ],
            "Resource": "*"
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy4",
            "Effect": "Allow",
            "Action": "SNS:Publish",
            "Resource": "*"
        },
               {
            "Sid": "LambdaCertificateExpiryPolicy5",
            "Effect": "Allow",
            "Action": "cloudwatch:ListMetrics",
            "Resource": "*"
        }
               {
            "Sid": "LambdaCertificateExpiryPolicy6",
            "Effect": "Allow",
            "Action": [
                "sqs:ChangeMessageVisibility",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ListQueueTags",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
              ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.lambda_role_certificate_expiry_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_certificate_expiry_dev[0].arn
}

###########################################################
# IAM Role & Policy for Lambda Certificate Expiration - UAT
###########################################################

resource "aws_iam_role" "lambda_role_certificate_expiry_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Certificate_Expiry_UAT"
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

resource "aws_iam_policy" "iam_policy_for_lambda_certificate_expiry_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_certificate_expiry_uat"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role certificate expiry uat"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid":"LambdaCertificateExpiryPolicy1",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-2:172753231260:*"
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:172753231260:log-group:/aws/lambda/handle-expiring-certificates:*"
            ]
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy3",
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:GetCertificate",
                "acm:ListCertificates",
                "acm:ListTagsForCertificate"
            ],
            "Resource": "*"
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy4",
            "Effect": "Allow",
            "Action": "SNS:Publish",
            "Resource": "*"
        },
               {
            "Sid": "LambdaCertificateExpiryPolicy5",
            "Effect": "Allow",
            "Action": "cloudwatch:ListMetrics",
            "Resource": "*"
        }
           {
            "Sid": "LambdaCertificateExpiryPolicy6",
            "Effect": "Allow",
            "Action": [
                "sqs:ChangeMessageVisibility",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ListQueueTags",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
              ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.lambda_role_certificate_expiry_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_certificate_expiry_uat[0].arn
}

############################################################
# IAM Role & Policy for Lambda Certificate Expiration - PROD
############################################################

resource "aws_iam_role" "lambda_role_certificate_expiry_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Certificate_Expiry_PROD"
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

resource "aws_iam_policy" "iam_policy_for_lambda_certificate_expiry_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_certificate_expiry_prod"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role certificate expiry prod"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid":"LambdaCertificateExpiryPolicy1",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-2:817985104434:*"
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:817985104434:log-group:/aws/lambda/handle-expiring-certificates:*"
            ]
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy3",
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:GetCertificate",
                "acm:ListCertificates",
                "acm:ListTagsForCertificate"
            ],
            "Resource": "*"
        },
        {
            "Sid":"LambdaCertificateExpiryPolicy4",
            "Effect": "Allow",
            "Action": "SNS:Publish",
            "Resource": "*"
        },
               {
            "Sid": "LambdaCertificateExpiryPolicy5",
            "Effect": "Allow",
            "Action": "cloudwatch:ListMetrics",
            "Resource": "*"
        }
           {
            "Sid": "LambdaCertificateExpiryPolicy6",
            "Effect": "Allow",
            "Action": [
                "sqs:ChangeMessageVisibility",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "sqs:ListQueueTags",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
              ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_certificate_expiry_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_certificate_expiry_prod[0].arn
}

###################
# SNS IAM Policies
###################

## Production

data "aws_iam_policy_document" "sns_topic_policy_ec2cw" {
  count     = local.is-production == true ? 1 : 0
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

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }

    resources = [
      aws_sns_topic.cw_alerts[0].arn
    ]
  }
}

## UAT

data "aws_iam_policy_document" "sns_topic_policy_uat_ec2cw" {
  count     = local.is-preproduction == true ? 1 : 0
  policy_id = "SnsUATTopicId"
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

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }

    resources = [
      aws_sns_topic.cw_uat_alerts[0].arn
    ]
  }
}

####################################################
# IAM User, Policy for MGN
####################################################

#tfsec:ignore:aws-iam-no-user-attached-policies 
#tfsec:ignore:AWS273
resource "aws_iam_user" "mgn_user" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also set to ignore"
  name = "MGN-Test"
  tags = local.tags
}
#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user_policy_attachment" "mgn_attach_policy" {
  #tfsec:ignore:aws-iam-no-user-attached-policies
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.mgn_user.name
  policy_arn = "arn:aws:iam::aws:policy/AWSApplicationMigrationFullAccess"
}

####################################################
# IAM User, Policy, Access Key for email
####################################################

#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "email" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also ignored"
  count = local.is-production == false ? 1 : 0
  name  = format("%s-%s-email_user", local.application_name, local.environment)
  tags = merge(local.tags,
    { Name = format("%s-%s-email_user", local.application_name, local.environment) }
  )
}

resource "aws_iam_access_key" "email" {
  count = local.is-production == false ? 1 : 0
  user  = aws_iam_user.email[0].name
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_user_policy" "email_policy" {
  # checkov:skip=CKV_AWS_40:"Directly attaching the policy makes more sense here"
  count  = local.is-production == false ? 1 : 0
  name   = "AmazonSesSendingAccess"
  user   = aws_iam_user.email[0].name
  policy = data.aws_iam_policy_document.email.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "email" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_356: Policy follows AWS guidance
  statement {
    actions = [
      "ses:SendRawEmail"
    ]
    resources = ["*"]
  }
}
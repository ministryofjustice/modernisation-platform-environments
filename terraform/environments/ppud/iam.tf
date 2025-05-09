
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
        "arn:aws:s3:::moj-infrastructure",
        "arn:aws:s3:::moj-infrastructure/*"
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
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:Start*",
          "ec2:Stop*"
        ],
        "Resource" : [
          "arn:aws:ec2:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
    }]
  })
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
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudwatch:DisableAlarmActions",
            "cloudwatch:EnableAlarmActions"
          ],
          "Resource" : [
            "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "sqs:ChangeMessageVisibility",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:ListQueueTags",
            "sqs:ReceiveMessage",
            "sqs:SendMessage"
          ],
          "Resource" : [
            "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
          ]
      }]
  })
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
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ],
      "Resource" : [
        "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*",
        "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"
      ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:ec2:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeAsync",
          "lambda:InvokeFunction",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
    }]
  })
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
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ],
      "Resource" : [
        "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*",
        "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"
      ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:ec2:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeAsync",
          "lambda:InvokeFunction",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
    }]
  })
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
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ],
      "Resource" : [
        "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*",
        "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"
      ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:ec2:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeAsync",
          "lambda:InvokeFunction",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
    }]
  })
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
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LambdaCertificateExpiryPolicy1",
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy2",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:log-group:/aws/lambda/handle-expiring-certificates:*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy3",
        "Effect" : "Allow",
        "Action" : [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate"
        ],
        "Resource" : [
          "arn:aws:acm:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:certificate/*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy4",
        "Effect" : "Allow",
        "Action" : "SNS:Publish",
        "Resource" : [
          "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy5",
        "Effect" : "Allow",
        "Action" : "cloudwatch:ListMetrics",
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy6",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
    }]
  })
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
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LambdaCertificateExpiryPolicy1",
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy2",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:log-group:/aws/lambda/handle-expiring-certificates:*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy3",
        "Effect" : "Allow",
        "Action" : [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate"
        ],
        "Resource" : [
          "arn:aws:acm:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:certificate/*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy4",
        "Effect" : "Allow",
        "Action" : "SNS:Publish",
        "Resource" : [
          "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy5",
        "Effect" : "Allow",
        "Action" : "cloudwatch:ListMetrics",
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      },
      {
        "Sid" : "LambdaCertificateExpiryPolicy6",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
    }]
  })
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
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "LambdaCertificateExpiryPolicy1",
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        },
        {
          "Sid" : "LambdaCertificateExpiryPolicy2",
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:log-group:/aws/lambda/handle-expiring-certificates:*"
          ]
        },
        {
          "Sid" : "LambdaCertificateExpiryPolicy3",
          "Effect" : "Allow",
          "Action" : [
            "acm:DescribeCertificate",
            "acm:GetCertificate",
            "acm:ListCertificates",
            "acm:ListTagsForCertificate"
          ],
          "Resource" : [
            "arn:aws:acm:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:certificate/*"
          ]
        },
        {
          "Sid" : "LambdaCertificateExpiryPolicy4",
          "Effect" : "Allow",
          "Action" : "SNS:Publish",
          "Resource" : [
            "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
          ]
        },
        {
          "Sid" : "LambdaCertificateExpiryPolicy5",
          "Effect" : "Allow",
          "Action" : "cloudwatch:ListMetrics",
          "Resource" : [
            "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
          ]
        },
        {
          "Sid" : "LambdaCertificateExpiryPolicy6",
          "Effect" : "Allow",
          "Action" : [
            "sqs:ChangeMessageVisibility",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:ListQueueTags",
            "sqs:ReceiveMessage",
            "sqs:SendMessage"
          ],
          "Resource" : [
            "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:Lambda-Queue-Production"
          ]
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_certificate_expiry_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_certificate_expiry_prod[0].arn
}

###################
# SNS IAM Policies
###################

# Production IAM SNS Policy

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
      "SNS:GetSubscriptionAttributes",
      "SNS:SetSubscriptionAttributes",
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:Unsubscribe",
      "SNS:ListSubscriptions",
      "SNS:ListSubscriptionsByTopic",
      "SNS:ListTopics",
      "SNS:Publish"
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

# Production IAM SNS Policy

data "aws_iam_policy_document" "sns_topic_policy_ec2_cw_uat" {
  count     = local.is-preproduction == true ? 1 : 0
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
      "SNS:GetSubscriptionAttributes",
      "SNS:SetSubscriptionAttributes",
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:Unsubscribe",
      "SNS:ListSubscriptions",
      "SNS:ListSubscriptionsByTopic",
      "SNS:ListTopics",
      "SNS:Publish"
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

# Development IAM SNS Policy

data "aws_iam_policy_document" "sns_topic_policy_ec2_cw_dev" {
  count     = local.is-development == true ? 1 : 0
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
      "SNS:GetSubscriptionAttributes",
      "SNS:SetSubscriptionAttributes",
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:Unsubscribe",
      "SNS:ListSubscriptions",
      "SNS:ListSubscriptionsByTopic",
      "SNS:ListTopics",
      "SNS:Publish"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }

    resources = [
      aws_sns_topic.cw_dev_alerts[0].arn
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

############################################################
# IAM Role & Policy for Lambda Signing Configuration - PROD
############################################################

resource "aws_iam_role" "aws_signer_role_prod" {
  count = local.is-production == true ? 1 : 0
  name  = "Signer-Role-For-Lambda-Production"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "signer.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "aws_signer_policy_prod" {
  count = local.is-production == true ? 1 : 0
  name  = "Signer-Policy-For-Lambda-Production"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:UpdateFunctionCodeSigningConfig",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:PutFunctionCodeSigningConfig",
          "lambda:InvokeFunction"
        ],
        Resource = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:function:*" # Grant access to all Lambda functions in the account
      },
      {
        Effect = "Allow",
        Action = [
          "signer:StartSigningJob",
          "signer:DescribeSigningJob",
          "signer:PutSigningProfile",
          "signer:GetSigningProfile",
          "signer:ListSigningJobs"
        ],
        Resource = [
          "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:/signing-profiles/0r1ihd4swpgdxsjmfe1ibqhvdpm3zg05le4uni20241008100713396700000002",
          "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:/signing-profiles/0r1ihd4swpgdxsjmfe1ibqhvdpm3zg05le4uni20241008100713396700000002/HzoPedNoUr"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_aws_signer_policy_to_aws_signer_role_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.aws_signer_role_prod[0].name
  policy_arn = aws_iam_policy.aws_signer_policy_prod[0].arn
}

############################################################
# IAM Role & Policy for Lambda Signing Configuration - UAT
############################################################

resource "aws_iam_role" "aws_signer_role_uat" {
  count = local.is-preproduction == true ? 1 : 0
  name  = "Signer-Role-For-Lambda-UAT"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "signer.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "aws_signer_policy_uat" {
  count = local.is-preproduction == true ? 1 : 0
  name  = "Signer-Policy-For-Lambda-UAT"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:UpdateFunctionCodeSigningConfig",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:PutFunctionCodeSigningConfig",
          "lambda:InvokeFunction"
        ],
        Resource = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:function:*" # Grant access to all Lambda functions in the account
      },
      {
        Effect = "Allow",
        Action = [
          "signer:StartSigningJob",
          "signer:DescribeSigningJob",
          "signer:PutSigningProfile",
          "signer:GetSigningProfile",
          "signer:ListSigningJobs"
        ],
        Resource = [
          "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:/signing-profiles/ucjvuurx21fa91xmhktdde5ognhxig1vahls8z20241008084937718900000002",
          "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:/signing-profiles/ucjvuurx21fa91xmhktdde5ognhxig1vahls8z20241008084937718900000002/ZYACVFPo1R"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_aws_signer_policy_to_aws_signer_role_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.aws_signer_role_uat[0].name
  policy_arn = aws_iam_policy.aws_signer_policy_uat[0].arn
}

############################################################
# IAM Role & Policy for Lambda Signing Configuration - DEV
############################################################

resource "aws_iam_role" "aws_signer_role_dev" {
  count = local.is-development == true ? 1 : 0
  name  = "Signer-Role-For-Lambda-Dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "signer.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "aws_signer_policy_dev" {
  count = local.is-development == true ? 1 : 0
  name  = "Signer-Policy-For-Lambda-Development"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:UpdateFunctionCodeSigningConfig",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:PutFunctionCodeSigningConfig",
          "lambda:InvokeFunction"
        ],
        Resource = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:function:*" # Grant access to all Lambda functions in the account
      },
      {
        Effect = "Allow",
        Action = [
          "signer:StartSigningJob",
          "signer:DescribeSigningJob",
          "signer:PutSigningProfile",
          "signer:GetSigningProfile",
          "signer:ListSigningJobs"
        ],
        Resource = [
          "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:/signing-profiles/grw77tzk96phtwcrceot5xlbt9veqixuyck04420241008100655411100000002",
          "arn:aws:signer:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:/signing-profiles/grw77tzk96phtwcrceot5xlbt9veqixuyck04420241008100655411100000002/AHvOa02ifI"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_aws_signer_policy_to_aws_signer_role_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.aws_signer_role_dev[0].name
  policy_arn = aws_iam_policy.aws_signer_policy_dev[0].arn
}

#############################################
# IAM Role & Policy for Send CPU graph - DEV
#############################################

resource "aws_iam_role" "lambda_role_cloudwatch_get_metric_data_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Cloudwatch_Get_Metric_Data_Dev"
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

resource "aws_iam_policy" "iam_policy_for_lambda_cloudwatch_get_metric_data_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_cloudwatch_get_metric_data_dev"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role cloudwatch get_metric_data development"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "CloudwatchMetricPolicy",
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:*"
        ],
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "S3BucketPolicy",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::moj-lambda-layers-dev",
          "arn:aws:s3:::moj-lambda-layers-dev/*"
        ]
      },
      {
        "Sid" : "SSMPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:parameter/klayers-account"
        ]
      },
      {
        "Sid" : "LogPolicy",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "SQSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "SESPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ses:*"
        ],
        "Resource" : [
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*",
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:identity/internaltest.ppud.justice.gov.uk"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.lambda_role_cloudwatch_get_metric_data_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_cloudwatch_get_metric_data_dev[0].arn
}

resource "aws_iam_policy_attachment" "attach_lambda_read_only_access_dev" {
  count      = local.is-development == true ? 1 : 0
  name       = "lambda-read-only-access-iam-attachment"
  roles      = [aws_iam_role.lambda_role_cloudwatch_get_metric_data_dev[0].id]
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "attach_lambda_cloudwatch_full_access_dev" {
  count      = local.is-development == true ? 1 : 0
  name       = "lambda-cloudwatch-full-access-iam-attachment"
  roles      = [aws_iam_role.lambda_role_cloudwatch_get_metric_data_dev[0].id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

resource "aws_iam_policy_attachment" "attach_lambda_ec2_read_only_access_dev" {
  count      = local.is-development == true ? 1 : 0
  name       = "lambda-ec2-read-only-access-iam-attachment"
  roles      = [aws_iam_role.lambda_role_cloudwatch_get_metric_data_dev[0].id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

#resource "aws_iam_policy_attachment" "attach_ses_full_access" {
#  count      = local.is-development == true ? 1 : 0
#  name       = "ses-full-access-iam-attachment"
#  roles      = [aws_iam_role.lambda_role_cloudwatch_get_metric_data_dev[0].id]
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
#}


#############################################
# IAM Role & Policy for Send CPU graph - PROD
#############################################

resource "aws_iam_role" "lambda_role_cloudwatch_get_metric_data_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Cloudwatch_Get_Metric_Data_Prod"
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

resource "aws_iam_policy" "iam_policy_for_lambda_cloudwatch_get_metric_data_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_cloudwatch_get_metric_data_prod"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role cloudwatch get_metric_data production"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "CloudwatchMetricPolicy",
      "Effect" : "Allow",
      "Action" : [
        "cloudwatch:*"
      ],
      "Resource" : [
        "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
      ]
      },
      {
        "Sid" : "S3BucketPolicy",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::moj-infrastructure",
          "arn:aws:s3:::moj-infrastructure/*"
        ]
      },
      {
        "Sid" : "SSMPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:parameter/klayers-account"
        ]
      },
      {
        "Sid" : "LogPolicy",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      },
      {
        "Sid" : "SQSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_cloudwatch_get_metric_data_prod[0].arn
}

resource "aws_iam_policy_attachment" "attach_lambda_read_only_access_prod" {
  count      = local.is-production == true ? 1 : 0
  name       = "lambda-read-only-access-iam-attachment"
  roles      = [aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].id]
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

# Attach AWSLambdaVPCAccessExecutionRole Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_vpc_access_policy_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy_attachment" "attach_lambda_cloudwatch_full_access_prod" {
  count      = local.is-production == true ? 1 : 0
  name       = "lambda-cloudwatch-full-access-iam-attachment"
  roles      = [aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

#################################################
# IAM Role & Policy for Security Hub report- PROD
#################################################

resource "aws_iam_role" "lambda_role_securityhub_get_data_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Securityhub_Get_Data_Prod"
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

resource "aws_iam_policy" "iam_policy_for_lambda_securityhub_get_data_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_securityhub_get_data__prod"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role securityhub get data production"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "SecurityHubPolicy",
      "Effect" : "Allow",
      "Action" : [
        "securityhub:*"
      ],
      "Resource" : [
        "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
      ]
      },
      {
        "Sid" : "LogPolicy",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      },
      {
        "Sid" : "SQSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_securityhub_get_data_to_lambda_role_securityhub_get_data_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_securityhub_get_data_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_securityhub_get_data_prod[0].arn
}

resource "aws_iam_policy_attachment" "attach_lambda_securityhub_readonly_prod" {
  count      = local.is-production == true ? 1 : 0
  name       = "lambda-securityhub-readonly-iam-attachment"
  roles      = [aws_iam_role.lambda_role_securityhub_get_data_prod[0].id]
  policy_arn = "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_policy_to_lambda_role_securityhub_get_data_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_securityhub_get_data_prod[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

################################################
# IAM Role & Policy for Security Hub report- DEV
################################################

resource "aws_iam_role" "lambda_role_securityhub_get_data_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Securityhub_Get_Data_Dev"
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

resource "aws_iam_policy" "iam_policy_for_lambda_securityhub_get_data_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_securityhub_get_data_dev"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role securityhub get data production"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "SecurityHubPolicy",
      "Effect" : "Allow",
      "Action" : [
        "securityhub:*"
      ],
      "Resource" : [
        "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
      ]
      },
      {
        "Sid" : "LogPolicy",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "SQSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      },
      {
        "Sid" : "SESPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ses:*"
        ],
        "Resource" : [
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*",
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:identity/internaltest.ppud.justice.gov.uk"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_securityhub_get_data_to_lambda_role_securityhub_get_data_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.lambda_role_securityhub_get_data_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_securityhub_get_data_dev[0].arn
}

resource "aws_iam_policy_attachment" "attach_lambda_securityhub_readonly_dev" {
  count      = local.is-development == true ? 1 : 0
  name       = "lambda-securityhub-readonly-iam-attachment"
  roles      = [aws_iam_role.lambda_role_securityhub_get_data_dev[0].id]
  policy_arn = "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"
}

################################################
# IAM Role & Policy for Security Hub report- UAT
################################################

resource "aws_iam_role" "lambda_role_securityhub_get_data_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Securityhub_Get_Data_UAT"
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

resource "aws_iam_policy" "iam_policy_for_lambda_securityhub_get_data_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_terraform_aws_lambda_role_securityhub_get_data_uat"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role securityhub get data production"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "SecurityHubPolicy",
      "Effect" : "Allow",
      "Action" : [
        "securityhub:*"
      ],
      "Resource" : [
        "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
      ]
      },
      {
        "Sid" : "LogPolicy",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      },
      {
        "Sid" : "SQSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      },
      {
        "Sid" : "SESPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ses:*"
        ],
        "Resource" : [
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*",
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:identity/uat.ppud.justice.gov.uk"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_securityhub_get_data_to_lambda_role_securityhub_get_data_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.lambda_role_securityhub_get_data_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_securityhub_get_data_uat[0].arn
}

resource "aws_iam_policy_attachment" "attach_lambda_securityhub_readonly_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  name       = "lambda-securityhub-readonly-iam-attachment"
  roles      = [aws_iam_role.lambda_role_securityhub_get_data_uat[0].id]
  policy_arn = "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"
}

#########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - DEV
#########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_database_source_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_database_source_dev"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_database_source_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_database_source_dev"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-database-source-dev[0].arn,
          "${aws_s3_bucket.moj-database-source-dev[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::mojap-data-engineering-production-ppud-dev",
          "arn:aws:s3:::mojap-data-engineering-production-ppud-dev/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_database_source_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_database_source_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_database_source_dev[0].arn
}

##########################################################
# IAM Role & Policy for S3 Bucket Replication to MPC - DEV
##########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_report_source_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_report_source_dev"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_report_source_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_report_source_dev"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-report-source-dev[0].arn,
          "${aws_s3_bucket.moj-report-source-dev[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::cloud-platform-db973d65892f599f6e78cb90252d7dc9",
          "arn:aws:s3:::cloud-platform-db973d65892f599f6e78cb90252d7dc9/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_report_source_dev" {
  count      = local.is-development == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_dev[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_report_source_dev[0].arn
}

##########################################################
# IAM Role & Policy for S3 Bucket Replication to MPC - UAT
##########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_report_source_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_report_source_uat"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_report_source_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_report_source_uat"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-report-source-uat[0].arn,
          "${aws_s3_bucket.moj-report-source-uat[0].arn}/*"
        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::cloud-platform-ffbd9073e2d0d537d825ebea31b441fc",
          "arn:aws:s3:::cloud-platform-ffbd9073e2d0d537d825ebea31b441fc/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_report_source_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_report_source_uat[0].arn
}

###########################################################
# IAM Role & Policy for S3 Bucket Replication to MPC - PROD
###########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_report_source_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_report_source_prod"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }
  EOF
}

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_report_source_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_report_source_prod"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "SourceBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ],
        "Resource" : [
          aws_s3_bucket.moj-report-source-prod[0].arn,
          "${aws_s3_bucket.moj-report-source-prod[0].arn}/*"

        ]
      },
      {
        "Sid" : "DestinationBucketPermissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ],
        "Resource" : [
          "arn:aws:s3:::cloud-platform-9c7fd5fc774969b089e942111a7d5671",
          "arn:aws:s3:::cloud-platform-9c7fd5fc774969b089e942111a7d5671/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_report_source_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_prod[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_report_source_prod[0].arn
}
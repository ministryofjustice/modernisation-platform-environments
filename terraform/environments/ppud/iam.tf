######################################################################################
# IAM Roles, Policies, Attachments and Profiles for SSM, S3, Security Hub & Cloudwatch
######################################################################################

#########################
# Development Environment
#########################

####################### IAM Roles and Attachments #######################

# Lambda role and attachment for invoking SSM & powershell on EC2 instances

resource "aws_iam_role" "lambda_role_invoke_ssm_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Invoke_SSM_Dev"
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

locals {
  lambda_invoke_ssm_policies_dev = local.is-development ? {
    "send_message_to_sqs"      = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_dev[0].arn
    "send_logs_to_cloudwatch"  = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_dev[0].arn
    "invoke_ssm_powershell"    = aws_iam_policy.iam_policy_lambda_invoke_ssm_powershell_dev[0].arn
    "invoke_ssm_ec2_instances" = aws_iam_policy.iam_policy_lambda_invoke_ssm_ec2_instances_dev[0].arn
    "lambda_invoke"            = aws_iam_policy.iam_policy_lambda_invoke_dev[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_invoke_ssm_dev" {
  for_each   = local.is-development ? local.lambda_invoke_ssm_policies_dev : {}
  role       = aws_iam_role.lambda_role_invoke_ssm_dev[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving ACM certificate expiry dates

resource "aws_iam_role" "lambda_role_get_certificate_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Certificate_Dev"
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


locals {
  lambda_get_certificate_policies_dev = local.is-development ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_dev[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_dev[0].arn
    "publish_sns"             = aws_iam_policy.iam_policy_lambda_publish_to_sns_dev[0].arn
    "get_certificate"         = aws_iam_policy.iam_policy_lambda_get_certificate_dev[0].arn
    #  "sqs_invoke"                     = aws_iam_policy.iam_policy_lambda_invoke_sqs_dev[0].arn
    "get_cloudwatch_metrics" = aws_iam_policy.iam_policy_lambda_get_cloudwatch_metrics_dev[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_certificate_dev" {
  for_each   = local.is-development ? local.lambda_get_certificate_policies_dev : {}
  role       = aws_iam_role.lambda_role_get_certificate_dev[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving data and metrics from cloudwatch

resource "aws_iam_role" "lambda_role_get_cloudwatch_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Cloudwatch_Dev"
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

locals {
  lambda_get_cloudwatch_policies_dev = local.is-development ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_dev[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_dev[0].arn
    "get_cloudwatch_metrics"  = aws_iam_policy.iam_policy_lambda_get_cloudwatch_metrics_dev[0].arn
    "invoke_ses"              = aws_iam_policy.iam_policy_lambda_invoke_ses_dev[0].arn
    "get_data_s3"             = aws_iam_policy.iam_policy_lambda_get_s3_data_dev[0].arn
    "get_klayers"             = aws_iam_policy.iam_policy_lambda_get_ssm_parameter_klayers_dev[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_cloudwatch_dev" {
  for_each   = local.is-development ? local.lambda_get_cloudwatch_policies_dev : {}
  role       = aws_iam_role.lambda_role_get_cloudwatch_dev[0].name
  policy_arn = each.value
}

resource "aws_iam_policy_attachment" "attach_lambda_cloudwatch_full_access_dev" {
  count      = local.is-development == true ? 1 : 0
  name       = "lambda-cloudwatch-full-access-iam-attachment"
  roles      = [aws_iam_role.lambda_role_get_cloudwatch_dev[0].id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

# Lambda role and attachment for retrieving security hub data

resource "aws_iam_role" "lambda_role_get_securityhub_data_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Securityhub_Data_Dev"
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

locals {
  lambda_get_securityhub_policies_dev = local.is-development ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_dev[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_dev[0].arn
    "invoke_ses"              = aws_iam_policy.iam_policy_lambda_invoke_ses_dev[0].arn
    "get_securityhub_data"    = aws_iam_policy.iam_policy_lambda_get_securityhub_data_dev[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_securityhub_data_dev" {
  for_each   = local.is-development ? local.lambda_get_securityhub_policies_dev : {}
  role       = aws_iam_role.lambda_role_get_securityhub_data_dev[0].name
  policy_arn = each.value
}

# Lambda role and attachment for ses logging

resource "aws_iam_role" "lambda_role_get_ses_logging_dev" {
  count              = local.is-development == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_SES_Logging_DEV"
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

locals {
  lambda_get_ses_logging_policies_dev = local.is-development ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_dev[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_dev[0].arn
    "publish_to_sns"          = aws_iam_policy.iam_policy_lambda_publish_to_sns_dev[0].arn
    "put_data_s3"             = aws_iam_policy.iam_policy_lambda_put_s3_data_dev[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_ses_logging_dev" {
  for_each   = local.is-development ? local.lambda_get_ses_logging_policies_dev : {}
  role       = aws_iam_role.lambda_role_get_ses_logging_dev[0].name
  policy_arn = each.value
}

####################### IAM Policies #######################

resource "aws_iam_policy" "iam_policy_lambda_send_message_to_sqs_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_send_message_to_sqs_${local.environment}"
  path        = "/"
  description = "Allows lambda to send messages to SQS queues in ppud-development account"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_publish_to_sns_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_publish_sns_${local.environment}"
  path        = "/"
  description = "Allows lambda to publish to sns"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_send_logs_cloudwatch_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_send_logs_cloudwatch_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to send logs to cloudwatch in ppud development account"
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
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_ssm_parameter_klayers_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_ssm_parameters_klayers_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get ssm parameters (account ID) for the klayers account"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:parameter/klayers-account"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ssm_powershell_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ssm_powershell_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke ssm to allow it to execute powershell commands"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*",
          "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ssm_ec2_instances_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ssm_ec2_instances_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke ssm commands on ec2 instances"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke functions"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_certificate_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_certificate_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get certificate details"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_cloudwatch_metrics_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_cloudwatch_metrics_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get cloudwatch metrics"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:*"
        ],
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_s3_data_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_s3_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get data from S3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.moj-infrastructure-dev[0].arn,
          "${aws_s3_bucket.moj-infrastructure-dev[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ses_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ses_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get send messages via ses"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
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

resource "aws_iam_policy" "iam_policy_lambda_get_securityhub_data_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_securityhub_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get security hub data "
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "securityhub:*"
        ],
        "Resource" : [
          "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_put_s3_data_dev" {
  count       = local.is-development == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_put_s3_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to put data into S3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
        ]
      }
    ]
  })
}

###########################
# Preproduction Environment
###########################

####################### IAM Roles and Attachments #######################

# Lambda role and attachment for invoking SSM & powershell on EC2 instances

resource "aws_iam_role" "lambda_role_invoke_ssm_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Invoke_SSM_UAT"
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

locals {
  lambda_invoke_ssm_policies_uat = local.is-preproduction ? {
    "send_message_to_sqs"      = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_uat[0].arn
    "send_logs_to_cloudwatch"  = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_uat[0].arn
    "invoke_ssm_powershell"    = aws_iam_policy.iam_policy_lambda_invoke_ssm_powershell_uat[0].arn
    "invoke_ssm_ec2_instances" = aws_iam_policy.iam_policy_lambda_invoke_ssm_ec2_instances_uat[0].arn
    "lambda_invoke"            = aws_iam_policy.iam_policy_lambda_invoke_uat[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_invoke_ssm_uat" {
  for_each   = local.is-preproduction ? local.lambda_invoke_ssm_policies_uat : {}
  role       = aws_iam_role.lambda_role_invoke_ssm_uat[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving security hub data

resource "aws_iam_role" "lambda_role_get_securityhub_data_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Securityhub_Data_UAT"
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

locals {
  lambda_get_securityhub_policies_uat = local.is-preproduction ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_uat[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_uat[0].arn
    "invoke_ses"              = aws_iam_policy.iam_policy_lambda_invoke_ses_uat[0].arn
    "get_securityhub_data"    = aws_iam_policy.iam_policy_lambda_get_securityhub_data_uat[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_securityhub_data_uat" {
  for_each   = local.is-preproduction ? local.lambda_get_securityhub_policies_uat : {}
  role       = aws_iam_role.lambda_role_get_securityhub_data_uat[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving ACM certificate expiry dates

resource "aws_iam_role" "lambda_role_get_certificate_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Certificate_UAT"
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

locals {
  lambda_get_certificate_policies_uat = local.is-preproduction ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_uat[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_uat[0].arn
    "publish_to_sns"          = aws_iam_policy.iam_policy_lambda_publish_to_sns_uat[0].arn
    "get_certificate"         = aws_iam_policy.iam_policy_lambda_get_certificate_uat[0].arn
    "get_cloudwatch_metrics"  = aws_iam_policy.iam_policy_lambda_get_cloudwatch_metrics_uat[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_certificate_uat" {
  for_each   = local.is-preproduction ? local.lambda_get_certificate_policies_uat : {}
  role       = aws_iam_role.lambda_role_get_certificate_uat[0].name
  policy_arn = each.value
}

# Lambda role and attachment for ses logging

resource "aws_iam_role" "lambda_role_get_ses_logging_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_SES_Logging_UAT"
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

locals {
  lambda_get_ses_logging_policies_uat = local.is-preproduction ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_uat[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_uat[0].arn
    "publish_to_sns"          = aws_iam_policy.iam_policy_lambda_publish_to_sns_uat[0].arn
    "put_data_s3"             = aws_iam_policy.iam_policy_lambda_put_s3_data_uat[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_ses_logging_uat" {
  for_each   = local.is-preproduction ? local.lambda_get_ses_logging_policies_uat : {}
  role       = aws_iam_role.lambda_role_get_ses_logging_uat[0].name
  policy_arn = each.value
}

####################### IAM Policies #######################

resource "aws_iam_policy" "iam_policy_lambda_send_message_to_sqs_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_send_message_to_sqs_${local.environment}"
  path        = "/"
  description = "Allows lambda to send messages to SQS queues in ppud preproduction account"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_publish_to_sns_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_publish_sns_${local.environment}"
  path        = "/"
  description = "Allows lambda to publish to sns"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_send_logs_cloudwatch_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_send_logs_cloudwatch_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to send logs to cloudwatch in ppud preproduction account"
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
          "arn:aws:logs:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ssm_powershell_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ssm_powershell_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke ssm to allow it to execute powershell commands"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*",
          "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ssm_ec2_instances_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ssm_ec2_instances_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke ssm commands on ec2 instances"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke functions"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_certificate_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_certificate_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get certificate details"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_cloudwatch_metrics_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_cloudwatch_metrics_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get cloudwatch metrics"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:*"
        ],
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_s3_data_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_s3_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get data from S3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.moj-infrastructure-uat[0].arn,
          "${aws_s3_bucket.moj-infrastructure-uat[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_put_s3_data_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_put_s3_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to put data into S3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ses_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ses_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get send messages via ses"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ses:*"
        ],
        "Resource" : [
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*",
          "arn:aws:ses:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:identity/uat.ppud.justice.gov.uk"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_securityhub_data_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_securityhub_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get security hub data "
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "securityhub:*"
        ],
        "Resource" : [
          "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
        ]
      }
    ]
  })
}

###########################
# Production Environment
###########################

####################### IAM Roles and Attachments #######################

# Lambda role and attachment for invoking SSM & powershell on EC2 instances

resource "aws_iam_role" "lambda_role_invoke_ssm_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Invoke_SSM_Prod"
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

locals {
  lambda_invoke_ssm_policies_prod = local.is-production ? {
    "send_message_to_sqs"      = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_prod[0].arn
    "send_logs_to_cloudwatch"  = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_prod[0].arn
    "invoke_ssm_powershell"    = aws_iam_policy.iam_policy_lambda_invoke_ssm_powershell_prod[0].arn
    "invoke_ssm_ec2_instances" = aws_iam_policy.iam_policy_lambda_invoke_ssm_ec2_instances_prod[0].arn
    "lambda_invoke"            = aws_iam_policy.iam_policy_lambda_invoke_prod[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_invoke_ssm_prod" {
  for_each   = local.is-production ? local.lambda_invoke_ssm_policies_prod : {}
  role       = aws_iam_role.lambda_role_invoke_ssm_prod[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving data and metrics from cloudwatch

resource "aws_iam_role" "lambda_role_get_cloudwatch_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Cloudwatch_Prod"
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

locals {
  lambda_get_cloudwatch_policies_prod = local.is-production ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_prod[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_prod[0].arn
    "get_cloudwatch_metrics"  = aws_iam_policy.iam_policy_lambda_get_cloudwatch_metrics_prod[0].arn
    "get_data_s3"             = aws_iam_policy.iam_policy_lambda_get_s3_data_prod[0].arn
    "get_elb_metrics"         = aws_iam_policy.iam_policy_lambda_get_s3_elb_metrics_prod[0].arn
    "get_klayers"             = aws_iam_policy.iam_policy_lambda_get_ssm_parameter_klayers_prod[0].arn
    "ec2_permissions"         = aws_iam_policy.iam_policy_lambda_ec2_permissions_prod[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_cloudwatch_prod" {
  for_each   = local.is-production ? local.lambda_get_cloudwatch_policies_prod : {}
  role       = aws_iam_role.lambda_role_get_cloudwatch_prod[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "attach_lambda_cloudwatch_full_access_to_get_cloudwatch_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_get_cloudwatch_prod[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

resource "aws_iam_role_policy_attachment" "attach_lambda_vpc_access_execution_prod" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.lambda_role_get_cloudwatch_prod[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda role and attachment for retrieving security hub data

resource "aws_iam_role" "lambda_role_get_securityhub_data_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Securityhub_Data_Prod"
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

locals {
  lambda_get_securityhub_policies_prod = local.is-production ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_prod[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_prod[0].arn
    "get_securityhub_data"    = aws_iam_policy.iam_policy_lambda_get_securityhub_data_prod[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_securityhub_data_prod" {
  for_each   = local.is-production ? local.lambda_get_securityhub_policies_prod : {}
  role       = aws_iam_role.lambda_role_get_securityhub_data_prod[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving ACM certificate expiry dates

resource "aws_iam_role" "lambda_role_get_certificate_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_Certificate_Prod"
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

locals {
  lambda_get_certificate_policies_prod = local.is-production ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_prod[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_prod[0].arn
    "publish_to_sns"          = aws_iam_policy.iam_policy_lambda_publish_to_sns_prod[0].arn
    "get_certificate"         = aws_iam_policy.iam_policy_lambda_get_certificate_prod[0].arn
    "get_cloudwatch_metrics"  = aws_iam_policy.iam_policy_lambda_get_cloudwatch_metrics_prod[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_certificate_prod" {
  for_each   = local.is-production ? local.lambda_get_certificate_policies_prod : {}
  role       = aws_iam_role.lambda_role_get_certificate_prod[0].name
  policy_arn = each.value
}

# Lambda role and attachment for retrieving elastic load balancer metrics from S3

resource "aws_iam_role" "lambda_role_get_elb_metrics_prod" {
  count              = local.is-production == true ? 1 : 0
  name               = "PPUD_Lambda_Function_Role_Get_ELB_Metrics_Prod"
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

locals {
  lambda_get_elb_metrics_policies_prod = local.is-production ? {
    "send_message_to_sqs"     = aws_iam_policy.iam_policy_lambda_send_message_to_sqs_prod[0].arn
    "send_logs_to_cloudwatch" = aws_iam_policy.iam_policy_lambda_send_logs_cloudwatch_prod[0].arn
    "get_cloudwatch_metrics"  = aws_iam_policy.iam_policy_lambda_get_cloudwatch_metrics_prod[0].arn
    "get_elb_metrics"         = aws_iam_policy.iam_policy_lambda_get_s3_elb_metrics_prod[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_get_elb_metrics_prod" {
  for_each   = local.is-production ? local.lambda_get_elb_metrics_policies_prod : {}
  role       = aws_iam_role.lambda_role_get_elb_metrics_prod[0].name
  policy_arn = each.value
}

resource "aws_iam_policy_attachment" "attach_lambda_cloudwatch_full_access_to_get_metrics_prod" {
  count      = local.is-production == true ? 1 : 0
  name       = "lambda-cloudwatch-full-access-to-elb-metrics-iam-attachment"
  roles      = [aws_iam_role.lambda_role_get_elb_metrics_prod[0].id]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

####################### IAM Policies #######################

resource "aws_iam_policy" "iam_policy_lambda_send_message_to_sqs_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_send_message_to_sqs_${local.environment}"
  path        = "/"
  description = "Allows lambda to send messages to SQS queues in ppud production account"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:SendMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:ReceiveMessage",
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sqs:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_publish_to_sns_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_publish_sns_${local.environment}"
  path        = "/"
  description = "Allows lambda to publish to sns"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_send_logs_cloudwatch_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_send_logs_cloudwatch_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to send logs to cloudwatch in ppud production account"
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_disable_alarms_cloudwatch_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_disable_alarms_cloudwatch_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to disable and enable alarms in cloudwatch in ppud production account"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:EnableAlarmActions"
        ],
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ssm_powershell_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ssm_powershell_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke ssm to allow it to execute powershell commands"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*",
          "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_ssm_ec2_instances_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_ssm_ec2_instances_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke ssm commands on ec2 instances"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_invoke_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_invoke_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to invoke functions"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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
      }
    ]
  })
}
resource "aws_iam_policy" "iam_policy_lambda_get_certificate_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_certificate_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get certificate details"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
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
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_s3_data_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_s3_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get data from S3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.moj-infrastructure[0].arn,
          "${aws_s3_bucket.moj-infrastructure[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_s3_elb_metrics_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_s3_elb_metrics_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to put and get ELB metric data in and from S3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.moj-lambda-metrics-prod[0].arn,
          "${aws_s3_bucket.moj-lambda-metrics-prod[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_cloudwatch_metrics_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_cloudwatch_metrics_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get cloudwatch metrics"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:*"
        ],
        "Resource" : [
          "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_securityhub_data_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_securityhub_data_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get security hub data "
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "securityhub:*"
        ],
        "Resource" : [
          "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_get_ssm_parameter_klayers_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_get_ssm_parameters_klayers_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to get ssm parameters (account ID) for the klayers account"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:parameter/klayers-account"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "iam_policy_lambda_ec2_permissions_prod" {
  count       = local.is-production == true ? 1 : 0
  name        = "aws_iam_policy_for_lambda_ec2_permissions_${local.environment}"
  path        = "/"
  description = "Allows lambda functions to have required ec2 permissions"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterface"
        ],
        "Resource" : [
          "arn:aws:ec2:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
        ]
      }
    ]
  })
}

##############################################
# EC2 Roles, Policies, Attachment and Profiles
##############################################

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
# IAM Policy for Production S3 access
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

##########################################################################################
# S3 Bucket Roles and Policies for S3 Buckets that replicate to Justice Digital S3 Buckets
##########################################################################################

#########################################################
# IAM Role & Policy for S3 Bucket Replication to DE - DEV
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

#########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - DEV
#########################################################

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

# new
#########################################################
# IAM Role & Policy for S3 Bucket Replication to DE - UAT
#########################################################

resource "aws_iam_role" "iam_role_s3_bucket_moj_database_source_uat" {
  count              = local.is-preproduction == true ? 1 : 0
  name               = "iam_role_s3_bucket_moj_database_source_uat"
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

resource "aws_iam_policy" "iam_policy_s3_bucket_moj_database_source_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  name        = "iam_policy_s3_bucket_moj_database_source_uat"
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
          aws_s3_bucket.moj-database-source-uat[0].arn,
          "${aws_s3_bucket.moj-database-source-uat[0].arn}/*"
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
          "arn:aws:s3:::mojap-data-engineering-production-ppud-preprod",
          "arn:aws:s3:::mojap-data-engineering-production-ppud-preprod/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_role_to_iam_policy_s3_bucket_moj_database_source_uat" {
  count      = local.is-preproduction == true ? 1 : 0
  role       = aws_iam_role.iam_role_s3_bucket_moj_database_source_uat[0].name
  policy_arn = aws_iam_policy.iam_policy_s3_bucket_moj_database_source_uat[0].arn
}

#########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - UAT
#########################################################

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

##########################################################
# IAM Role & Policy for S3 Bucket Replication to CP - PROD
##########################################################

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
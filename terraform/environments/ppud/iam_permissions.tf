#######################################################################
# Dynamic IAM Roles, Policies and Attachments for Lambda Functions
#######################################################################

locals {
  # Role configurations with their associated policies
  lambda_role_configs = {
    invoke_ssm = {
      description = "Lambda Function Role for invoking SSM & powershell on EC2 instances"
      policies = [
        "send_message_to_sqs",
        "send_logs_to_cloudwatch", 
        "invoke_ssm_powershell",
        "invoke_ssm_ec2_instances",
        "lambda_invoke"
      ]
    }
    get_cloudwatch = {
      description = "Lambda Function Role for retrieving data and metrics from cloudwatch"
      policies = [
        "send_message_to_sqs",
        "send_logs_to_cloudwatch",
        "get_cloudwatch_metrics",
        "invoke_ses",
        "get_data_s3",
        "get_klayers"
      ]
      prod_policies = [
        "get_elb_metrics",
        "ec2_permissions"
      ]
      managed_policies = ["arn:aws:iam::aws:policy/CloudWatchFullAccessV2"]
      vpc_policies = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
    }
    get_securityhub_data = {
      description = "Lambda Function Role for retrieving security hub data"
      policies = [
        "send_message_to_sqs",
        "send_logs_to_cloudwatch",
        "invoke_ses",
        "get_securityhub_data"
      ]
    }
    get_ses_logging = {
      description = "Lambda Function Role for SES logging"
      policies = [
        "send_message_to_sqs",
        "send_logs_to_cloudwatch",
        "publish_to_sns",
        "put_data_s3"
      ]
    }
  }

  # Environment configurations
  iam_environments = {
    development = {
      condition = local.is-development
      account_key = "ppud-development"
      s3_buckets = {
        infrastructure = "aws_s3_bucket.moj-infrastructure-dev[0].arn"
        log_files = "aws_s3_bucket.moj-log-files-dev[0].arn"
      }
    }
    preproduction = {
      condition = local.is-preproduction
      account_key = "ppud-preproduction"
      s3_buckets = {
        infrastructure = "aws_s3_bucket.moj-infrastructure-uat[0].arn"
        log_files = "aws_s3_bucket.moj-log-files-uat[0].arn"
      }
    }
    production = {
      condition = local.is-production
      account_key = "ppud-production"
      s3_buckets = {
        infrastructure = "aws_s3_bucket.moj-infrastructure[0].arn"
        log_files = "aws_s3_bucket.moj-lambda-metrics-prod[0].arn"
      }
    }
  }

  # Generate role instances for each environment
  lambda_role_instances = flatten([
    for role_key, role_config in local.lambda_role_configs : [
      for env_key, env_config in local.iam_environments : {
        key = "${role_key}_${env_key}"
        role_key = role_key
        env_key = env_key
        role_config = role_config
        env_config = env_config
      } if env_config.condition
    ]
  ])

  lambda_role_instances_map = {
    for instance in local.lambda_role_instances : instance.key => instance
  }
}

#######################################################################
# IAM Roles
#######################################################################

resource "aws_iam_role" "lambda_role_v2" {
  for_each = local.lambda_role_instances_map

  name = "PPUD_Lambda_Function_Role_${title(replace(each.value.role_key, "_", "_"))}_${title(each.value.env_key)}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

#######################################################################
# IAM Policies
#######################################################################

# Create unique policies per environment
locals {
  unique_policies = {
    for combo in flatten([
      for env_key, env_config in local.iam_environments : [
        for policy_name in [
          "send_message_to_sqs",
          "send_logs_to_cloudwatch",
          "get_cloudwatch_metrics",
          "invoke_ses",
          "publish_to_sns",
          "invoke_ssm_powershell",
          "invoke_ssm_ec2_instances",
          "lambda_invoke",
          "get_securityhub_data",
          "get_data_s3",
          "put_data_s3",
          "get_klayers",
          "get_elb_metrics",
          "ec2_permissions"
        ] : {
          key = "${policy_name}_${env_key}"
          policy_name = policy_name
          env_key = env_key
          env_config = env_config
        } if env_config.condition
      ]
    ]) : combo.key => combo
  }
}

resource "aws_iam_policy" "lambda_policies_v2" {
  for_each = local.unique_policies

  name = "aws_iam_policy_${each.value.policy_name}_${each.value.env_key}"
  path = "/"
  description = "Lambda policy for ${each.value.policy_name} in ${each.value.env_key} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      each.value.policy_name == "send_message_to_sqs" ? {
        Effect = "Allow"
        Action = ["sqs:SendMessage", "sqs:ChangeMessageVisibility", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl", "sqs:ListQueueTags", "sqs:ReceiveMessage", "sns:Publish"]
        Resource = ["arn:aws:sqs:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "send_logs_to_cloudwatch" ? {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:aws:logs:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "get_cloudwatch_metrics" ? {
        Effect = "Allow"
        Action = ["cloudwatch:*"]
        Resource = ["arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "invoke_ses" ? {
        Effect = "Allow"
        Action = ["ses:*"]
        Resource = ["arn:aws:ses:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "publish_to_sns" ? {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = ["arn:aws:sns:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "invoke_ssm_powershell" ? {
        Effect = "Allow"
        Action = ["ssm:SendCommand", "ssm:GetCommandInvocation"]
        Resource = ["arn:aws:ssm:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*", "arn:aws:ssm:eu-west-2::document/AWS-RunPowerShellScript"]
      } : each.value.policy_name == "invoke_ssm_ec2_instances" ? {
        Effect = "Allow"
        Action = ["ec2:DescribeInstances", "ssm:SendCommand", "ssm:GetCommandInvocation"]
        Resource = ["arn:aws:ec2:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "lambda_invoke" ? {
        Effect = "Allow"
        Action = ["lambda:InvokeAsync", "lambda:InvokeFunction", "ssm:SendCommand", "ssm:GetCommandInvocation"]
        Resource = ["arn:aws:lambda:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "get_securityhub_data" ? {
        Effect = "Allow"
        Action = ["securityhub:*"]
        Resource = ["arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      } : each.value.policy_name == "get_data_s3" ? {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [each.value.env_config.s3_buckets.infrastructure, "${each.value.env_config.s3_buckets.infrastructure}/*"]
      } : each.value.policy_name == "put_data_s3" ? {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:PutObjectAcl", "s3:ListBucket"]
        Resource = [each.value.env_config.s3_buckets.log_files, "${each.value.env_config.s3_buckets.log_files}/*"]
      } : each.value.policy_name == "get_klayers" ? {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = ["arn:aws:ssm:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:parameter/klayers-account"]
      } : each.value.policy_name == "get_elb_metrics" ? {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::moj-lambda-metrics-prod", "arn:aws:s3:::moj-lambda-metrics-prod/*"]
      } : {
        Effect = "Allow"
        Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterface"]
        Resource = ["arn:aws:ec2:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:*"]
      }
    ]
  })
}

#######################################################################
# IAM Role Policy Attachments
#######################################################################

resource "aws_iam_role_policy_attachment" "attach_lambda_policies_v2" {
  for_each = {
    for combo in flatten([
      for role_key, role_instance in local.lambda_role_instances_map : concat(
        [
          for policy in role_instance.role_config.policies : {
            key = "${role_key}_${policy}"
            role_key = role_key
            policy_key = "${policy}_${role_instance.env_key}"
          }
        ],
        role_instance.env_key == "production" ? [
          for policy in try(role_instance.role_config.prod_policies, []) : {
            key = "${role_key}_${policy}"
            role_key = role_key
            policy_key = "${policy}_${role_instance.env_key}"
          }
        ] : []
      )
    ]) : combo.key => combo
  }

  role = aws_iam_role.lambda_role_v2[each.value.role_key].name
  policy_arn = aws_iam_policy.lambda_policies_v2[each.value.policy_key].arn
}

# Managed policy attachments
resource "aws_iam_role_policy_attachment" "attach_managed_policies_v2" {
  for_each = {
    for combo in flatten([
      for role_key, role_instance in local.lambda_role_instances_map : [
        for policy in try(role_instance.role_config.managed_policies, []) : {
          key = "${role_key}_managed_${replace(policy, "/[^a-zA-Z0-9]/", "_")}"
          role_key = role_key
          policy_arn = policy
        }
      ]
    ]) : combo.key => combo
  }

  role = aws_iam_role.lambda_role_v2[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

# VPC policy attachments (production only)
resource "aws_iam_role_policy_attachment" "attach_vpc_policies_v2" {
  for_each = {
    for combo in flatten([
      for role_key, role_instance in local.lambda_role_instances_map : [
        for policy in try(role_instance.role_config.vpc_policies, []) : {
          key = "${role_key}_vpc_${replace(policy, "/[^a-zA-Z0-9]/", "_")}"
          role_key = role_key
          policy_arn = policy
        } if role_instance.env_key == "production"
      ]
    ]) : combo.key => combo
  }

  role = aws_iam_role.lambda_role_v2[each.value.role_key].name
  policy_arn = each.value.policy_arn
}
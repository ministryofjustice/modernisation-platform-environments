#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instance
# This is required to enable SSH via Systems Manager
# and also to allow access to an S3 bucket in which 
# Oracle and Weblogic installation files are held
#------------------------------------------------------------------------------

resource "aws_iam_role" "ec2_common_role" {
  name                 = "ec2-common-role"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  tags = merge(
    local.tags,
    {
      Name = "ec2-common-role"
    },
  )
}

# create policy document for access to s3 bucket
data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [module.s3-bucket.bucket.arn,
    "${module.s3-bucket.bucket.arn}/*"]
  }
}

# attach s3 document as inline policy
resource "aws_iam_role_policy" "s3_bucket_access" {
  name   = "nomis-apps-bucket-access"
  role   = aws_iam_role.ec2_common_role.name
  policy = data.aws_iam_policy_document.s3_bucket_access.json
}

# create policy document to write Session Manager logs to CloudWatch
data "aws_iam_policy_document" "session_manager_logging" {
  # commented out as not encypting with KMS currently as the the role
  # assumed by the user connecting also needs the GenerateDataKey permission
  # see https://mojdt.slack.com/archives/C01A7QK5VM1/p1637603085030600
  # statement { # for session and log encryption using KMS
  #   effect = "Allow"
  #   actions = [
  #     "kms:Decrypt",
  #     "kms:GenerateDataKey"
  #   ]
  #   resources = [aws_kms_key.session_manager.arn]
  # }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.session_manager.arn,
      "${aws_cloudwatch_log_group.session_manager.arn}:log-stream:*"
    ]
  }
}

# attach session logging document as inline policy
resource "aws_iam_role_policy" "session_manager_logging" {
  name   = "session-manager-logging"
  role   = aws_iam_role.ec2_common_role.name
  policy = data.aws_iam_policy_document.session_manager_logging.json
}

resource "aws_iam_instance_profile" "ec2_common_profile" {
  name = "ec2-common-profile"
  role = aws_iam_role.ec2_common_role.name
  path = "/"
}

#------------------------------------------------------------------------------
# Keypair for ec2-user
#------------------------------------------------------------------------------
resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user"
  public_key = local.application_data.accounts[local.environment].public_key
  tags = merge(
    local.tags,
    {
      Name = "ec2-user"
    },
  )
}

#------------------------------------------------------------------------------
# Session Manager Logging and Settings
#------------------------------------------------------------------------------

# Ignore warnings regarding log groups not encrypted using customer-managed
# KMS keys - note they are still encrypted with default KMS key
#tfsec:ignore:AWS089
resource "aws_cloudwatch_log_group" "session_manager" {
  #checkov:skip=CKV_AWS_158:skip KMS CMK encryption check while logging solution is being determined
  name              = "session-manager-logs"
  retention_in_days = local.application_data.accounts[local.environment].session_manager_log_retention_days

  tags = merge(
    local.tags,
    {
      Name = "session-manager-logs"
    },
  )
}

resource "aws_ssm_document" "session_manager_settings" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode(
    {
      schemaVersion = "1.0"
      description   = "Document to hold regional settings for Session Manager"
      sessionType   = "Standard_Stream",
      inputs = {
        cloudWatchLogGroupName      = aws_cloudwatch_log_group.session_manager.name
        cloudWatchEncryptionEnabled = false
        cloudWatchStreamingEnabled  = true
        s3BucketName                = ""
        s3KeyPrefix                 = ""
        s3EncryptionEnabled         = false
        idleSessionTimeout          = "20"
        kmsKeyId                    = "" # aws_kms_key.session_manager.arn
        runAsEnabled                = false
        runAsDefaultUser            = ""
        shellProfile = {
          windows = ""
          linux   = ""
        }
      }
    }
  )
}

# commented out for now - see https://mojdt.slack.com/archives/C01A7QK5VM1/p1637603085030600
# resource "aws_kms_key" "session_manager" {
#   enable_key_rotation = true

#   tags = merge(
#     local.tags,
#     {
#       Name = "session_manager"
#     },
#   )
# }

# resource "aws_kms_alias" "session_manager_alias" {
#   name          = "alias/session_manager_key"
#   target_key_id = aws_kms_key.session_manager.arn
# }

#------------------------------------------------------------------------------
# Cloud Watch Agent
#------------------------------------------------------------------------------

resource "aws_ssm_association" "cloud_watch_agent" {
  name             = "AWS-ConfigureAWSPackage"
  association_name = "install-cloud-watch-agent"
  parameters = {
    action = "Install"
    name   = "AmazonCloudWatchAgent"
  }
  targets {
    key = "InstanceIds"
    values = [
      aws_instance.db_server.id,
      aws_instance.weblogic_server.id
    ]
  }
  apply_only_at_cron_interval = false
  # schedule_expression = 
}

resource "aws_ssm_association" "manage_cloud_watch_agent_linux" {
  name             = "AmazonCloudWatch-ManageAgent"
  association_name = "manage-cloud-watch-agent"
  parameters = {
    action                        = "configure"
    mode                          = "ec2"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = aws_ssm_parameter.cloud_watch_config_linux.name
    optionalRestart               = "yes"
  }
  targets {
    key    = "tag:os_type"
    values = ["Linux"]
  }
  apply_only_at_cron_interval = false
  # schedule_expression = 
}

resource "aws_ssm_parameter" "cloud_watch_config_linux" {
  description = "cloud watch agent config for linux"
  name        = "cloud-watch-config-linux"
  type        = "String"
  value       = file("./templates/cloud_watch_linux.json")

  tags = merge(
    local.tags,
    {
      Name = "cloud-watch-config-linux"
    },
  )
}

#------------------------------------------------------------------------------
# EventBridge for CloudWatch Agent Config Changes
#------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "cloud_watch_agent_linux" {
  name        = "update-cloud-watch-agent-linux"
  description = "Update Cloud Watch Agent on Linux instances when config file is changed"
  is_enabled  = true

  event_pattern = jsonencode(
    {
      detail-type = ["Parameter Store Change"]
      source      = ["aws.ssm"]
      resources   = [aws_ssm_parameter.cloud_watch_config_linux.arn]
      detail = {
        operation = ["Update"]
      }
    }
  )

  tags = merge(
    local.tags,
    {
      Name = "cloud-watch-config-linux"
    },
  )
}

resource "aws_cloudwatch_event_target" "cloud_watch_agent_linux" {
  target_id = "update-cloud-watch-agent-linux"
  arn       = "arn:aws:ssm:${local.region}::document/AmazonCloudWatch-ManageAgent"
  input = jsonencode(
    {
      action                        = "configure"
      mode                          = "ec2"
      optionalConfigurationSource   = "ssm"
      optionalConfigurationLocation = aws_ssm_parameter.cloud_watch_config_linux.name
      optionalRestart               = "yes"
    }
  )
  rule = aws_cloudwatch_event_rule.cloud_watch_agent_linux.name
  # role_arn = aws_iam_role.ssm_run_command.arn

  run_command_targets {
    key    = "tag:os_type"
    values = ["Linux"]
  }
}

# policy and role to allow run command
data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_runcommand" {
  statement {
    effect  = "Allow"
    actions = ["ssm:SendCommand"]
    resources = [
      "arn:aws:ec2:${local.region}:${local.environment_management.account_ids[terraform.workspace]}:instance/*",
      # limit to only running the cloud watch config document
      "arn:aws:ssm:${local.region}:*:document/AmazonCloudWatch-ManageAgent"
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      aws_ssm_parameter.cloud_watch_config_linux.arn
    ]
  }
}

resource "aws_iam_role" "ssm_run_command" {
  name               = "ssm-run-command"
  description        = "role for EventBridge to invoke run command on EC2"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
  inline_policy {
    name   = "EventBridgeRunCommand"
    policy = data.aws_iam_policy_document.eventbridge_runcommand.json
  }

  tags = merge(
    local.tags,
    {
      Name = "EventBridgeRunCommand"
    },
  )
}

# module "eventbridge" {
#   source  = "terraform-aws-modules/eventbridge/aws"
#   version = "1.13.2"

#   # bus_name = "default"
#   rules = {
#     cloud_watch_agent = {
#       description = "watch for changes to Cloud Watch Agent config"
#       enabled     = true
#       event_pattern = jsonencode(
#         {
#           "detail-type" : ["Parameter Store Change"],
#           "source" : ["aws.ssm"],
#           "resources" : [aws_ssm_parameter.cloud_watch_config_linux.arn],
#           "detail" : {
#             "operation" : ["Update"]
#           }
#         }
#       )
#     }
#   }

#   targets = {
#     cloud_watch_agent = [
#       {
#         name = "update-cloud-watch-agent-linux"
#         arn  = "arn:aws:ssm:${local.region}::document/AmazonCloudWatch-ManageAgent"
#         input = {
#           action                        = "configure"
#           mode                          = "ec2"
#           optionalConfigurationSource   = "ssm"
#           optionalConfigurationLocation = aws_ssm_parameter.cloud_watch_config_linux.name
#           optionalRestart               = "yes"
#         }
#         run_command_targets = {
#           key    = "tag:os_type"
#           values = ["Linux"]
#         }
#       }
#     ]
#   }
#   create_bus = false
# }
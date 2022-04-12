#------------------------------------------------------------------------------
# Common IAM policies for all ec2 instance profiles
#------------------------------------------------------------------------------

# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
data "aws_iam_policy_document" "ssm_custom" {
  #tfsec:ignore:AWS099:this is derived from AmazonSSMManagedInstanceCore managed policy
  #checkov:skip=CKV_AWS_111:this is derived from AmazonSSMManagedInstanceCore managed policy
  statement {
    sid    = "CustomSsmPolicy"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AccessCloudWatchConfigParameter"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [aws_ssm_parameter.cloud_watch_config_linux.arn]
  }
}

# create policy document for access to s3 artefact bucket
data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    sid    = "AccessToInstallationArtefactBucket"
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
    sid    = "WriteSessionManagerLogs"
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

# combine ec2-common policy documents 
data "aws_iam_policy_document" "ec2_common_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.ssm_custom.json,
    data.aws_iam_policy_document.s3_bucket_access.json,
    data.aws_iam_policy_document.session_manager_logging.json
  ]
}

# create single managed policy
resource "aws_iam_policy" "ec2_common_policy" {
  name        = "ec2-common-policy"
  path        = "/"
  description = "Common policy for all ec2 instances"
  policy      = data.aws_iam_policy_document.ec2_common_combined.json
  tags = merge(
    local.tags,
    {
      Name = "ec2-common-policy"
    },
  )
}

# create list of common managed policies that can be attached to ec2 instance profiles
locals {
  ec2_common_managed_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    aws_iam_policy.ec2_common_policy.arn
  ]
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

resource "aws_ssm_document" "cloud_watch_agent" {
  name            = "InstallAndManageCloudWatchAgent"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/install-and-manage-cwagent.yaml")

  tags = merge(
    local.tags,
    {
      Name = "install-and-manage-cloud-watch-agent"
    },
  )
}

resource "aws_ssm_association" "manage_cloud_watch_agent_linux" {
  name             = aws_ssm_document.cloud_watch_agent.name
  association_name = "manage-cloud-watch-agent"
  parameters = { # name of ssm parameter containing cloud watch agent config file
    optionalConfigurationLocation = aws_ssm_parameter.cloud_watch_config_linux.name
  }
  targets {
    key    = "tag:os_type"
    values = ["Linux"]
  }
  apply_only_at_cron_interval = false
  schedule_expression         = "cron(45 7 ? * TUE *)"
}

resource "aws_ssm_parameter" "cloud_watch_config_linux" {
  #checkov:skip=CKV2_AWS_34:there should not be anything secret in this config
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

# TODO: config for windows

#------------------------------------------------------------------------------
# SSM Agent - update Systems Manager Agent
#------------------------------------------------------------------------------

resource "aws_ssm_association" "update_ssm_agent" {
  name             = "AWS-UpdateSSMAgent" # this is an AWS provided document
  association_name = "update-ssm-agent"
  parameters = {
    allowDowngrade = "false"
  }
  targets {
    # we could just target all instances, but this would also include the bastion, which gets rebuilt everyday
    key    = "tag:os_type"
    values = ["Linux", "Windows"]
  }
  apply_only_at_cron_interval = false
  schedule_expression         = "cron(30 7 ? * TUE *)"
}

#------------------------------------------------------------------------------
# Scheduled overnight shutdown
# This is a pretty basic implementation until Mod Platform build a platform
# wide solution.  State Manager does not allow cron expressions like MON-FRI
# so we need to create a separate association for each day in order to deal with
# weekends.  Alternatively we could use Eventbridge rules as a trigger, but its 
# slightly more complex to setup the IAM roles for that.
# 
# Note that instances created throught the Weblogic module are not in scope as
# they are managed by an autoscaling group, and therefore are not tagged as targets
#------------------------------------------------------------------------------

locals {
  weekdays = ["MON", "TUE", "WED", "THU", "FRI"]
}

# Scheduled start
resource "aws_ssm_association" "ec2_scheduled_start" {
  for_each                         = toset(local.weekdays)
  name                             = "AWS-StartEC2Instance" # this is an AWS provided document
  association_name                 = "ec2_scheduled_start_${each.value}"
  automation_target_parameter_name = "InstanceId"
  parameters = {
    AutomationAssumeRole = aws_iam_role.ssm_ec2_start_stop.arn
  }
  targets {
    key    = "tag:always_on"
    values = ["false"]
  }
  apply_only_at_cron_interval = true
  schedule_expression         = "cron(0 7 ? * ${each.value} *)"
}

# Scheduled stop
resource "aws_ssm_association" "ec2_scheduled_stop" {
  for_each                         = toset(local.weekdays)
  name                             = "AWS-StopEC2Instance" # this is an AWS provided document
  association_name                 = "ec2_scheduled_stop_${each.value}"
  automation_target_parameter_name = "InstanceId"
  parameters = {
    AutomationAssumeRole = aws_iam_role.ssm_ec2_start_stop.arn
  }
  targets {
    key    = "tag:always_on"
    values = ["false"]
  }
  apply_only_at_cron_interval = true
  schedule_expression         = "cron(0 19 ? * ${each.value} *)"
}

resource "aws_iam_role" "ssm_ec2_start_stop" {
  name                 = "ssm-ec2-start-stop"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ssm.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
    # todo: This policy gives a lot of permissions. We should create a custom policy if we keep the solution long term 
  ]
  tags = merge(
    local.tags,
    {
      Name = "ssm-ec2-start-stop"
    },
  )
}
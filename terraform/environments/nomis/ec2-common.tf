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
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  tags = merge(
    local.tags,
    {
      Name = "ec2-common-role"
    },
  )
}

resource "aws_iam_role" "ec2_database_role" {
  name                 = "ec2-database-role"
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
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  tags = merge(
    local.tags,
    {
      Name = "ec2-database-role"
    },
  )
}



# create instance profile from IAM role
resource "aws_iam_instance_profile" "ec2_common_profile" {
  name = "ec2-common-profile"
  role = aws_iam_role.ec2_common_role.name
  path = "/"
}

# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
data "aws_iam_policy_document" "ssm_custom" {
  #tfsec:ignore:AWS099:this is derived from AmazonSSMManagedInstanceCore managed policy
  #checkov:skip=CKV_AWS_111:this is derived from AmazonSSMManagedInstanceCore managed policy
  statement {
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
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [aws_ssm_parameter.cloud_watch_config_linux.arn]
  }
}
### TODO: Do these have to be inline if they're reused for multiple roles?

# attach SSM document as inline policy ec2_common_role
resource "aws_iam_role_policy" "ssm_custom" {
  name   = "custom-SSM-manged-instance-core"
  role   = aws_iam_role.ec2_common_role.name
  policy = data.aws_iam_policy_document.ssm_custom.json
}

# attach SSM document as inline policy ec2_database_role
resource "aws_iam_role_policy" "ssm_db_custom" {
  name   = "custom-SSM-manged-instance-core-for-db"
  role   = aws_iam_role.ec2_database_role.name
  policy = data.aws_iam_policy_document.ssm_custom.json
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

# attach s3 document as inline policy ec2_database_role

resource "aws_iam_role_policy" "s3_db_bucket_access" {
  name   = "nomis-apps-bucket-access-for-db"
  role   = aws_iam_role.ec2_database_role.name
  policy = data.aws_iam_policy_document.s3_bucket_access.json
}

data "aws_iam_policy_document" "s3_db_backup_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [module.nomis-db-backup-bucket.bucket.arn,
    "${module.nomis-db-backup-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_db_backup_bucket_access" {
  name   = "nomis-apps-bucket-access-for-db-backup"
  role   = aws_iam_role.ec2_database_role.name
  policy = data.aws_iam_policy_document.s3_db_backup_bucket_access.json
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

# attach session logging document as inline policy ec2_database_role
resource "aws_iam_role_policy" "db_session_manager_logging" {
  name   = "db_session-manager-logging"
  role   = aws_iam_role.ec2_database_role.name
  policy = data.aws_iam_policy_document.session_manager_logging.json
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
    # currently all instances created through the nomis-stack module are tagged 'false'
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
    # currently all instances created through the nomis-stack module are tagged 'false'
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
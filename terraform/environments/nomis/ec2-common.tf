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
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
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

resource "aws_cloudwatch_log_group" "session_manager" {

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

resource "aws_kms_key" "session_manager" {
  enable_key_rotation = true

  tags = merge(
    local.tags,
    {
      Name = "session_manager"
    },
  )
}

resource "aws_kms_alias" "session_manager_alias" {
  name          = "alias/session_manager_key"
  target_key_id = aws_kms_key.session_manager.arn
}
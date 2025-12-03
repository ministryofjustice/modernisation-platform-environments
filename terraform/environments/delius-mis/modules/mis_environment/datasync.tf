# DataSync configuration for syncing S3 bucket to FSX share
# This configuration sets up DataSync to transfer files from an S3 bucket in a different acc      SECRET_ARN           = data.aws_secretsmanager_secret.datasync_ad_admin_password[0].arnunt
# to the FSX Windows file system share accessible at \\share.delius-mis-<env>.internal\share\dfiinterventions\dfi

#############################################
### Data Sources
#############################################
data "aws_subnet" "private_subnet" {
  count = var.datasync_config != null ? 1 : 0
  id    = var.account_config.private_subnet_ids[0]
}

#############################################
### Secrets Manager for FSX Credentials
#############################################
# Data source to read the existing AD admin password from Secrets Manager
data "aws_secretsmanager_secret" "datasync_ad_admin_password" {
  count = var.datasync_config != null ? 1 : 0
  name  = "delius-mis-${var.env_name}-ad-admin-password"
}

data "aws_secretsmanager_secret_version" "datasync_ad_admin_password" {
  count     = var.datasync_config != null ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.datasync_ad_admin_password[0].id
}

locals {
  # Use the existing AD admin password and a fixed username
  fsx_credentials = var.datasync_config != null ? {
    username = "Admin" # Use the fixed Admin username
    password = data.aws_secretsmanager_secret_version.datasync_ad_admin_password[0].secret_string
  } : null
}

#############################################
### Lambda Function for Automatic Password Updates
#############################################
resource "aws_iam_role" "datasync_password_updater_role" {
  count = var.datasync_config != null ? 1 : 0
  name  = "${var.app_name}-${var.env_name}-datasync-password-updater"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "datasync_password_updater_policy" {
  count = var.datasync_config != null ? 1 : 0
  name  = "${var.app_name}-${var.env_name}-datasync-password-updater-policy"
  role  = aws_iam_role.datasync_password_updater_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.aws_secretsmanager_secret.datasync_ad_admin_password[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "datasync:UpdateLocationFsxWindows",
          "datasync:DescribeLocationFsxWindows"
        ]
        Resource = aws_datasync_location_fsx_windows_file_system.dfi_fsx_destination[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "fsx:DescribeFileSystems",
        ]
        Resource = "arn:aws:fsx:*:*:*"
      }
    ]
  })
}

# Lambda function code archive
data "archive_file" "lambda_zip" {
  count       = var.datasync_config != null ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/datasync_password_updater.zip"
  source {
    content  = <<EOF
import boto3
import json
import os

def handler(event, context):
    datasync = boto3.client('datasync')
    secretsmanager = boto3.client('secretsmanager')
    
    try:
        # Get the current password from Secrets Manager
        secret_response = secretsmanager.get_secret_value(
            SecretId=os.environ['SECRET_ARN']
        )
        current_password = secret_response['SecretString']
        
        # Update the DataSync location with the current password
        datasync.update_location_fsx_windows(
            LocationArn=os.environ['DATASYNC_LOCATION_ARN'],
            User='Admin',
            Password=current_password,
            Domain=os.environ['FSX_DOMAIN']
        )
        
        print(f"Successfully updated DataSync location with current password")
        return {
            'statusCode': 200,
            'body': json.dumps('Password updated successfully')
        }
        
    except Exception as e:
        print(f"Error updating DataSync location: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}

resource "aws_lambda_function" "datasync_password_updater" {
  count         = var.datasync_config != null ? 1 : 0
  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "${var.app_name}-${var.env_name}-datasync-password-updater"
  role          = aws_iam_role.datasync_password_updater_role[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256

  environment {
    variables = {
      DATASYNC_LOCATION_ARN = aws_datasync_location_fsx_windows_file_system.dfi_fsx_destination[0].arn
      SECRET_ARN            = data.aws_secretsmanager_secret.datasync_ad_admin_password[0].arn
      FSX_DOMAIN            = var.datasync_config.fsx_domain
    }
  }

  tags = local.tags
}

# Schedule the Lambda to run 30 minutes before DataSync task to ensure fresh password
resource "aws_cloudwatch_event_rule" "pre_datasync_password_update" {
  count = var.datasync_config != null ? 1 : 0
  name  = "${var.app_name}-${var.env_name}-pre-datasync-password-update"

  # Run 15 minutes before the DataSync schedule to ensure fresh password
  # Default: Lambda at 04:00 UTC, DataSync at 04:15 UTC
  # Can be overridden with var.datasync_config.lambda_schedule_expression
  schedule_expression = var.datasync_config.lambda_schedule_expression
}

resource "aws_cloudwatch_event_target" "pre_datasync_lambda_target" {
  count = var.datasync_config != null ? 1 : 0
  rule  = aws_cloudwatch_event_rule.pre_datasync_password_update[0].name
  arn   = aws_lambda_function.datasync_password_updater[0].arn
}

resource "aws_lambda_permission" "allow_scheduled_execution" {
  count         = var.datasync_config != null ? 1 : 0
  statement_id  = "AllowExecutionFromSchedule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.datasync_password_updater[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pre_datasync_password_update[0].arn
}

#############################################
### DataSync Agent Security Group
#############################################
resource "aws_security_group" "datasync_agent" {
  count = var.datasync_config != null ? 1 : 0

  name        = "${var.app_name}-${var.env_name}-datasync-agent"
  description = "Security group for DataSync agent"
  vpc_id      = var.account_info.vpc_id

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-datasync-agent" }
  )
}

# Allow communication with FSX share
resource "aws_vpc_security_group_egress_rule" "datasync_agent_smb" {
  count = var.datasync_config != null ? 1 : 0

  security_group_id            = aws_security_group.datasync_agent[0].id
  description                  = "SMB to FSX"
  referenced_security_group_id = aws_security_group.fsx.id
  from_port                    = 445
  ip_protocol                  = "tcp"
  to_port                      = 445
}

# Allow all communication with FSX security group (for DataSync requirements)
resource "aws_vpc_security_group_egress_rule" "datasync_agent_fsx_all" {
  count = var.datasync_config != null ? 1 : 0

  security_group_id            = aws_security_group.datasync_agent[0].id
  description                  = "All traffic to FSX security group for DataSync"
  referenced_security_group_id = aws_security_group.fsx.id
  ip_protocol                  = "-1"
}

# Allow outbound for S3 access (via NAT Gateway or S3 VPC endpoint)
resource "aws_vpc_security_group_egress_rule" "datasync_agent_s3" {
  count = var.datasync_config != null ? 1 : 0

  security_group_id = aws_security_group.datasync_agent[0].id
  description       = "HTTPS for S3 access"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Allow activation traffic (required for initial setup)
resource "aws_vpc_security_group_ingress_rule" "datasync_agent_activation" {
  count = var.datasync_config != null ? 1 : 0

  security_group_id = aws_security_group.datasync_agent[0].id
  description       = "HTTP for agent activation"
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

#############################################
### DataSync IAM Role for S3 Access
#############################################
resource "aws_iam_role" "datasync_s3_role" {
  count = var.datasync_config != null ? 1 : 0

  name = "${var.app_name}-${var.env_name}-datasync-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# IAM policy for accessing the source S3 bucket in different account
resource "aws_iam_role_policy" "datasync_s3_source_policy" {
  count = var.datasync_config != null ? 1 : 0

  name = "${var.app_name}-${var.env_name}-datasync-s3-source-policy"
  role = aws_iam_role.datasync_s3_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:List*",
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectAcl",
          "s3:GetObjectVersionAcl"
        ]
        Resource = [
          var.datasync_config.source_s3_bucket_arn,
          "${var.datasync_config.source_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM policy for CloudWatch logging
resource "aws_iam_role_policy" "datasync_cloudwatch_logs_policy" {
  count = var.datasync_config != null ? 1 : 0

  name = "${var.app_name}-${var.env_name}-datasync-cloudwatch-logs-policy"
  role = aws_iam_role.datasync_s3_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.datasync_logs[0].arn}:*"
      }
    ]
  })
}

#############################################
### DataSync S3 Location (Source)
#############################################
resource "aws_datasync_location_s3" "dfi_source_bucket" {
  count = var.datasync_config != null ? 1 : 0

  s3_bucket_arn = var.datasync_config.source_s3_bucket_arn
  subdirectory  = var.datasync_config.source_s3_subdirectory

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role[0].arn
  }

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-dfi-source-s3" }
  )
}

#############################################
### DataSync FSX Location (Destination)
#############################################
resource "aws_datasync_location_fsx_windows_file_system" "dfi_fsx_destination" {
  count = var.datasync_config != null ? 1 : 0

  # Use FSX file system ARN and specific subdirectory for DFI reports
  fsx_filesystem_arn = aws_fsx_windows_file_system.mis_share.arn
  subdirectory       = "/share/dfiinterventions/dfi/"

  # Authentication details - using the existing AD admin credentials
  # The password comes from the existing AD admin secret that gets rotated automatically
  user     = local.fsx_credentials.username
  password = local.fsx_credentials.password
  domain   = var.datasync_config.fsx_domain

  security_group_arns = [aws_security_group.datasync_agent[0].arn]

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-dfi-fsx-destination" }
  )

  # Ignore password changes since Lambda function handles password updates automatically
  lifecycle {
    ignore_changes = [password]
  }

  depends_on = [
    data.aws_secretsmanager_secret_version.datasync_ad_admin_password
  ]
}

#############################################
### DataSync Task
#############################################
resource "aws_datasync_task" "dfi_s3_to_fsx" {
  count = var.datasync_config != null ? 1 : 0

  name                     = "${var.app_name}-${var.env_name}-dfi-s3-to-fsx-sync"
  source_location_arn      = aws_datasync_location_s3.dfi_source_bucket[0].arn
  destination_location_arn = aws_datasync_location_fsx_windows_file_system.dfi_fsx_destination[0].arn

  # CloudWatch logging configuration
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs[0].arn

  options {
    preserve_deleted_files = "PRESERVE" # keep files on the destination if they've been removed from source, change to REMOVE if needed

    # Transfer options - Normal sync behavior
    bytes_per_second = var.datasync_config.bandwidth_throttle != null ? var.datasync_config.bandwidth_throttle : -1 # defaults to unlimited
    task_queueing    = "ENABLED"
    transfer_mode    = "ALL" # Transfer all files
    verify_mode      = "POINT_IN_TIME_CONSISTENT"
    overwrite_mode   = "ALWAYS" # Overwrite existing files on destination

    # Windows FSX specific options
    posix_permissions = "NONE" # POSIX permissions not supported for Windows file systems
    uid               = "NONE" # UID not supported for Windows file systems
    gid               = "NONE" # GID not supported for Windows file systems

    # Logging
    log_level = "BASIC"
  }

  schedule {
    schedule_expression = var.datasync_config.schedule_expression
  }

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-dfi-s3-to-fsx-sync" }
  )

  depends_on = [
    aws_datasync_location_s3.dfi_source_bucket,
    aws_datasync_location_fsx_windows_file_system.dfi_fsx_destination,
    aws_cloudwatch_log_group.datasync_logs
  ]
}

#############################################
### CloudWatch Log Group for DataSync
#############################################
resource "aws_cloudwatch_log_group" "datasync_logs" {
  count = var.datasync_config != null ? 1 : 0

  name              = "/aws/datasync/${var.app_name}-${var.env_name}-dfi-sync"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-datasync-logs" }
  )
}

# Resource policy to allow DataSync service to write to CloudWatch Logs
resource "aws_cloudwatch_log_resource_policy" "datasync_logs_policy" {
  count = var.datasync_config != null ? 1 : 0

  policy_name = "${var.app_name}-${var.env_name}-datasync-logs-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.datasync_logs[0].arn}:*"
      }
    ]
  })
}

#############################################
### Security Group Rules for FSX to allow DataSync
#############################################
# Allow DataSync to connect to FSX via SMB
resource "aws_vpc_security_group_ingress_rule" "fsx_datasync_smb" {
  count = var.datasync_config != null ? 1 : 0

  security_group_id            = aws_security_group.fsx.id
  description                  = "Allow DataSync SMB access to FSX"
  referenced_security_group_id = aws_security_group.datasync_agent[0].id
  from_port                    = 445
  ip_protocol                  = "tcp"
  to_port                      = 445
}

# Allow all traffic from DataSync agent to FSX (for DataSync requirements)
resource "aws_vpc_security_group_ingress_rule" "fsx_datasync_all" {
  count = var.datasync_config != null ? 1 : 0

  security_group_id            = aws_security_group.fsx.id
  description                  = "Allow all DataSync traffic to FSX"
  referenced_security_group_id = aws_security_group.datasync_agent[0].id
  ip_protocol                  = "-1"
}

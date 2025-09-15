# DataSync configuration for syncing S3 bucket to FSX share
# This configuration sets up DataSync to transfer files from an S3 bucket in a different account
# to the FSX Windows file system share accessible at \\share.delius-mis-<env>.internal\share\dfiinterventions\dfi

#############################################
### Data Sources
#############################################
data "aws_subnet" "private_subnet" {
  count = var.datasync_config != null ? 1 : 0
  id    = var.account_config.private_subnet_ids[0]
}

#############################################
### VPC Endpoints for DataSync (NOT SUPPORTED in shared VPCs)
#############################################
# NOTE: VPC endpoints cannot be created in shared VPCs, so DataSync agent
# will need to be activated manually or use public internet for activation

#############################################
### Secrets Manager for FSX Credentials
#############################################
resource "aws_secretsmanager_secret" "datasync_fsx_credentials" {
  count = var.datasync_config != null ? 1 : 0

  name        = "${var.app_name}-${var.env_name}-datasync-fsx-credentials"
  description = "FSX credentials for DataSync agent to access the Windows file share. Content should be manually populated after creation."

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-datasync-fsx-credentials" }
  )
}

# Create initial placeholder version - content will be manually updated later
resource "aws_secretsmanager_secret_version" "datasync_fsx_credentials" {
  count = var.datasync_config != null ? 1 : 0

  secret_id = aws_secretsmanager_secret.datasync_fsx_credentials[0].id
  secret_string = jsonencode({
    username = "PLACEHOLDER_USERNAME"
    password = "PLACEHOLDER_PASSWORD"
  })

  # Ignore changes to secret content after initial creation
  # This allows manual updates via AWS Console/CLI without Terraform overwriting
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Data source to read the FSX credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "datasync_fsx_credentials" {
  count      = var.datasync_config != null ? 1 : 0
  secret_id  = aws_secretsmanager_secret.datasync_fsx_credentials[0].id
  depends_on = [aws_secretsmanager_secret_version.datasync_fsx_credentials]
}

locals {
  fsx_credentials = var.datasync_config != null ? jsondecode(data.aws_secretsmanager_secret_version.datasync_fsx_credentials[0].secret_string) : {
    username = "PLACEHOLDER_USERNAME"
    password = "PLACEHOLDER_PASSWORD"
  }
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
  subdirectory       = "/share/dfiinterventions/dfi"

  # Authentication details - using local values that will be set from secrets
  # NOTE: The credentials must be manually updated in Secrets Manager after initial deployment
  # for the DataSync task to function properly
  user     = local.fsx_credentials.username
  password = local.fsx_credentials.password
  domain   = var.datasync_config.fsx_domain

  security_group_arns = [aws_security_group.datasync_agent[0].arn]

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-dfi-fsx-destination" }
  )

  depends_on = [
    data.aws_secretsmanager_secret_version.datasync_fsx_credentials
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
    preserve_deleted_files = "PRESERVE" # keep files on the destination if they've been removed from source

    # Transfer options - Normal sync behavior
    bytes_per_second = var.datasync_config.bandwidth_throttle != null ? var.datasync_config.bandwidth_throttle : -1
    task_queueing    = "ENABLED"
    transfer_mode    = "CHANGED" # Only transfer changed files
    verify_mode      = "POINT_IN_TIME_CONSISTENT"
    overwrite_mode   = "ALWAYS" # Overwrite existing files on destination

    # Windows FSX specific options
    posix_permissions = "NONE" # POSIX permissions not supported for Windows file systems
    uid               = "NONE" # UID not supported for Windows file systems
    gid               = "NONE" # GID not supported for Windows file systems

    # Logging
    log_level = "TRANSFER"
  }

  schedule {
    schedule_expression = var.datasync_config.schedule_expression != null ? var.datasync_config.schedule_expression : "cron(* 4 * * ? *)" # DEFAULT Daily at 4:00 AM UTC (5:00 AM BST)
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

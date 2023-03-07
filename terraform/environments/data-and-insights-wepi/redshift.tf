# Redshift subnet group configuration
resource "aws_redshift_subnet_group" "wepi_redhsift_subnet_group" {
  name       = "wepi-redshift-${local.environment}-subnet-group"
  subnet_ids = data.aws_subnets.shared-data.ids

  tags = merge(
    local.tags,
    {
      Name = "wepi-redshift-${local.environment}-subnet-group"
    }
  )
}

# Redshift parameter group
resource "aws_redshift_parameter_group" "wepi_redshift_param_group" {
  name   = "wepi-redshift-${local.environment}-param-group"
  family = local.application_data.accounts[local.environment].redshift_param_group_family

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }
}

# Main Redshift cluster configuration
resource "aws_redshift_cluster" "wepi_redshift_cluster" {
  depends_on = [
    # Ensure that the bucket policy can created/updated before making changes to the cluster
    aws_s3_bucket_policy.wepi_redshift_logging_bucket_policy
  ]

  #checkov:skip=CKV_AWS_71: "Cluster logging temporarily disabled whilst issue is raised to AWS."
  cluster_identifier = "wepi-redshift-${local.environment}-cluster"
  database_name      = "wepi${local.environment}db"

  master_username = "wepidbadmin"
  master_password = random_password.wepi_redshift_admin_pw.result

  node_type       = local.application_data.accounts[local.environment].redshift_node_type
  cluster_type    = local.application_data.accounts[local.environment].redshift_cluster_node_count > 1 ? "multi-node" : "single-node"
  number_of_nodes = local.application_data.accounts[local.environment].redshift_cluster_node_count

  encrypted  = true
  kms_key_id = aws_kms_key.wepi_kms_cmk.arn

  publicly_accessible  = false
  enhanced_vpc_routing = true
  vpc_security_group_ids = [
    aws_security_group.wepi_sg_allow_redshift.id
  ]
  cluster_subnet_group_name = aws_redshift_subnet_group.wepi_redhsift_subnet_group.name

  cluster_parameter_group_name = aws_redshift_parameter_group.wepi_redshift_param_group.name

  aqua_configuration_status = "enabled"

  automated_snapshot_retention_period = local.application_data.accounts[local.environment].redshift_auto_snapshot_retention
  manual_snapshot_retention_period    = local.application_data.accounts[local.environment].redshift_manual_snapshot_retention
  skip_final_snapshot                 = true
  /* 
  logging {
    enable               = true
    bucket_name          = aws_s3_bucket.wepi_redshift_logging_bucket.id
    s3_key_prefix        = "wepi-redshift-logs"
    log_destination_type = "s3"
  } */

  tags = merge(
    local.tags,
    {
      Name = "wepi-redshift-${local.environment}-cluster"
    }
  )

  lifecycle {
    ignore_changes = [
      master_password
    ]
  }
}

# Redshift snapshot schedule and association
resource "aws_redshift_snapshot_schedule" "wepi_redshift_snapshot_sched" {
  identifier = "wepi-redshift-${local.environment}-snapshot-sched"
  definitions = [
    local.application_data.accounts[local.environment].redshift_snapshot_cron
  ]

  tags = local.tags
}

resource "aws_redshift_snapshot_schedule_association" "wepi_redshift_snapshot_assoc" {
  cluster_identifier  = aws_redshift_cluster.wepi_redshift_cluster.id
  schedule_identifier = aws_redshift_snapshot_schedule.wepi_redshift_snapshot_sched.id
}

# Redshift cluster pause and resume
resource "aws_redshift_scheduled_action" "wepi_redshift_pause_schedule" {
  count = local.application_data.accounts[local.environment].redshift_pause_cluster_enabled ? 1 : 0

  name     = "wepi-redshift-${local.environment}-pause-schedule"
  schedule = local.application_data.accounts[local.environment].redshift_pause_cluster_cron
  iam_role = aws_iam_role.wepi_iam_role_redshift_scheduler.arn

  target_action {
    pause_cluster {
      cluster_identifier = aws_redshift_cluster.wepi_redshift_cluster.cluster_identifier
    }
  }
}

resource "aws_redshift_scheduled_action" "wepi_redshift_resume_schedule" {
  count = local.application_data.accounts[local.environment].redshift_pause_cluster_enabled ? 1 : 0

  name     = "wepi-redshift-${local.environment}-resume-schedule"
  schedule = local.application_data.accounts[local.environment].redshift_resume_cluster_cron
  iam_role = aws_iam_role.wepi_iam_role_redshift_scheduler.arn

  target_action {
    resume_cluster {
      cluster_identifier = aws_redshift_cluster.wepi_redshift_cluster.cluster_identifier
    }
  }
}

# Redshift cluster IAM roles
resource "aws_redshift_cluster_iam_roles" "wepi_redshift_iam_roles" {
  cluster_identifier   = aws_redshift_cluster.wepi_redshift_cluster.cluster_identifier
  default_iam_role_arn = aws_iam_role.wepi_iam_role_redshift_default.arn
  iam_role_arns = [
    aws_iam_role.wepi_iam_role_redshift_default.arn
  ]
}

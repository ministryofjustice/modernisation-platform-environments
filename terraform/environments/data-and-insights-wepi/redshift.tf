# Redshift subnet group configuration
resource "aws_redshift_subnet_group" "wepi_redhsift_subnet_group" {
  name       = "wepi-redshift-${local.environment}-subnet-group"
  subnet_ids = data.aws_subnets.wepi_vpc_subnets_data_all.id

  tags = merge(
    local.tags,
    {
      Name = "wepi-redshift-${local.environment}-subnet-group"
    }
  )
}

# Redshift parameter group
resource "aws_redshift_parameter_group" "wepi_redshift_prama_group" {
  name   = "wepi-redshift-${local.environment}-param-group"
  family = local.app_data.accounts[local.environment].redshift_param_group_family

  parameter {
    name  = "require_ssl"
    value = "true"
  }
}

# Main Redshift cluster configuration
resource "aws_redshift_cluster" "wepi_redshift_cluster" {
  cluster_identifier = "wepi-redshift-${local.environment}-cluster"
  database_name      = "wepi${local.environment}db"

  master_username = "wepidbadmin"
  master_password = random_password.wepi_redshift_admin_pw.result

  node_type       = local.app_data.accounts[local.environment].redshift_node_type
  cluster_type    = local.app_data.accounts[local.environment].redshift_cluster_node_count > 1 ? "multi-node" : "single-node"
  number_of_nodes = local.app_data.accounts[local.environment].redshift_cluster_node_count

  encrypted   = true
  kms_key_arn = aws_kms_key.wepi_kms_cmk.arn

  enhanced_vpc_routing      = true
  vpc_security_group_ids    = "TO-DO"
  cluster_subnet_group_name = aws_redshift_subnet_group.wepi_redhsift_subnet_group.name

  cluster_parameter_group_name = "TO-DO"

  aqua_configuration_status = "enabled"

  automated_snapshot_retention_period = local.app_data.accounts[local.environment].redshift_auto_snapshot_retention
  manual_snapshot_retention_period    = local.app_data.accounts[local.environment].redshift_manual_snapshot_retention

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

# Redshift snapshot schedule and assoication
resource "aws_redshift_snapshot_schedule" "wepi_redshift_snapshot_sched" {
  identifier = "wepi-redshift-${local.environment}-snapshot-sched"
  definitions = [
    local.app_data.accounts[local.environment].redshift_snapshot_cron
  ]

  tags = local.tags
}

resource "aws_redshift_snapshot_schedule_association" "wepi_redshift_snapshot_assoc" {
  cluster_identifier  = aws_redshift_cluster.wepi_redshift_cluster.id
  schedule_identifier = aws_redshift_snapshot_schedule.wepi_redshift_snapshot_sched.id
}

# Redshift cluster pause and resume
resource "aws_redshift_scheduled_action" "wepi_redshift_pause_schedule" {
  count = local.app_data.accounts[local.environment].redshift_pause_cluster_enabled ? 1 : 0

  name     = "wepi-redshift-${local.environment}-pause-schedule"
  schedule = local.app_data.accounts[local.environment].redshift_pause_cluster_cron
  iam_role = aws_iam_role.wepi_iam_role_redshift_scheduler.arn

  target_action {
    pause_cluster {
      cluster_identifier = aws_redshift_cluster.wepi_redshift_cluster.cluster_identifier
    }
  }
} 

resource "aws_redshift_scheduled_action" "wepi_redshift_resume_schedule" {
  count = local.app_data.accounts[local.environment].redshift_pause_cluster_enabled ? 1 : 0

  name     = "wepi-redshift-${local.environment}-resume-schedule"
  schedule = local.app_data.accounts[local.environment].redshift_resume_cluster_cron
  iam_role = aws_iam_role.wepi_iam_role_redshift_scheduler.arn

  target_action {
    resume_cluster {
      cluster_identifier = aws_redshift_cluster.wepi_redshift_cluster.cluster_identifier
    }
  }
}

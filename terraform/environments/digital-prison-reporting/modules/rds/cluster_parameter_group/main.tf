################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_rds_cluster_parameter_group" "this" {
  count = var.create_db_cluster_parameter_group ? 1 : 0

  name        = var.db_cluster_parameter_group_use_name_prefix ? null : var.db_cluster_parameter_group_name
  name_prefix = var.db_cluster_parameter_group_use_name_prefix ? "${var.db_cluster_parameter_group_name}-" : null
  description = var.db_cluster_parameter_group_description
  family      = var.db_cluster_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_cluster_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}
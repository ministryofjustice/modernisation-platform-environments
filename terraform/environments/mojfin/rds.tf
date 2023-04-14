



resource "aws_db_subnet_group" "appdbsubnetgroup" {
  name       = "${local.application_name}-${local.environment}-subnetgrp"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

 tags = merge(
    local.tags, 
   { "Name" = "${local.application_name}-${local.environment}-subnetgrp"},
    {"Keep" = "true"}

 )

}

resource "aws_db_parameter_group" "default" {
  name   = "rds-oracle"
  family = "oracle-se2-19"
  description = "${local.application_name}-${local.environment}-parametergroup"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = merge(
    local.tags, 
   { "Name" = "mojfinsubnetgrp"},
    {"Keep" = "true"}
 )
}
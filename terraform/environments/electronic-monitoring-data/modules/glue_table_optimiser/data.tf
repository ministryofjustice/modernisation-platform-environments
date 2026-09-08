data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "external" "glue_tables_by_database" {
  for_each = setunion(var.databases, var.dbt_databases)

  program = ["bash", "${path.module}/scripts/list_glue_tables.sh"]

  query = {
    database_name = each.value
    region        = data.aws_region.current.name
  }
}

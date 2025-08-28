resource "aws_glue_catalog_database" "moj_resource_link" {
  name = "moj_resource_link"

  target_database {
    catalog_id    = local.producer_account_id
    database_name = "moj"
    region        = data.aws_region.current.name
  }

  # depends_on = [aws_lakeformation_permissions.table_share_all, aws_lakeformation_permissions.table_share_selected]
  lifecycle {
    ignore_changes = [
      # Change to description  require alter permissions which aren't typicically granted or needed
      description
    ]
  }
}

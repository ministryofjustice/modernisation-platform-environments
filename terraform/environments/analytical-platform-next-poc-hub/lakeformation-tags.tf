module "lakeformation_tags" {
  source = "../../modules/analytical-platform-next/lakeformation/tag-ontology"
}

resource "aws_lakeformation_resource_lf_tags" "main_shared_tbl" {
  table {
    database_name = aws_glue_catalog_database.main.name
    name          = aws_glue_catalog_table.main_shared_tbl.name
  }
  lf_tag {
    key   = "access"
    value = "yes"
  }
}

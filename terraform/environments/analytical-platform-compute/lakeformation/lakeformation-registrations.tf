resource "aws_lakeformation_resource" "example" {
  arn      = "arn:aws:s3:::mojap-derived-tables"
  role_arn = module.lake_formation_to_data_production_mojap_derived_tables_role.iam_role_arn
}

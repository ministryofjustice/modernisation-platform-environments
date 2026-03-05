resource "aws_glue_catalog_table" "example" {
  name          = "test_table"
  database_name = "example_database"

  storage_descriptor {
    location      = "s3://mojap-next-poc-data/wildcard_db/alpha_tbl/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    columns {
      name = "name"
      type = "string"
    }
  }

  parameters = {
    "classification" = "csv"
  }
}

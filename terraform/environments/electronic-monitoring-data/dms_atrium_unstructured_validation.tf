resource "aws_glue_catalog_database" "atrium_unstructured_db" {
  name = "atrium_unstructured"
}

resource "aws_glue_catalog_table" "atrium_unstructured_table" {
  name          = "atrium_unstructured"
  database_name = aws_glue_catalog_database.atrium_unstructured_db.name
  description   = "Table containing the queryable form of the JSON relating to the structure of the unstructured Atrium data"


  table_type = "EXTERNAL_TABLE"
  parameters = {
    classification = "json"
    EXTERNAL = "TRUE"
  }


  storage_descriptor {
    location      = "s3://em-data-store-20240131094334066000000004/g4s/dev_access/2024-02-16/json/" #This will change after testing to work for production and live
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"
    compressed = false


    ser_de_info {
      name                  = "s3-stream"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"


      parameters = {
        "ignore.malformed.json" = "TRUE"
        "dots.in.keys"          = "FALSE"
        "case.insensitive"      = "TRUE"
        "mapping"               = "TRUE"
      }
    }

    columns {
      name = "data"
      type = "struct<ParentGroup:string,SubGroup:string,PrimaryField:string,SecondaryField:string,ReportType:string,FileName:string,FileSize:int,Modified:string>"
    }
  }
}

resource "aws_iam_role" "atrium_glue_role" {
  name = "atrium-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "atrium_glue_role_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

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
    location      = "${aws_s3_bucket.data_store.id}/g4s/dev_access/2024-02-16/json_luke/" #This will change after testing to work for production and live
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"
    compressed = false
    number_of_buckets = -1


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
      name = "ParentGroup"
      type = "string"
    }
    columns {
      name = "parentgroup"
      type = "string"
    }
    columns {
      name = "subgroup"
      type = "string"
    }
    columns {
      name = "primaryfield"
      type = "string"
    }
    columns {
      name = "secondaryfield"
      type = "string"
    }
    columns {
      name = "reporttype"
      type = "string"
    }
    columns {
      name = "filename"
      type = "string"
    }
    columns {
      name = "filesize"
      type = "int"
    }
    columns {
      name = "modified"
      type = "datetime"
    }
  }
}

resource "aws_glue_crawler" "atrium_unstructured_crawler" {
  name         = "atrium_unstructured_crawler"
  role         = aws_iam_role.atrium_glue_role.arn
  database_name = aws_glue_catalog_database.atrium_unstructured_db.name

  s3_target {
    path = "${aws_s3_bucket.data_store.id}/g4s/dev_access/2024-02-16/json_luke/"
  }

  schema_change_policy {
    delete_behavior = "DEPRECATE_IN_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  classifiers = [aws_glue_classifier.atrium_json_classifier.name]
}

resource "aws_glue_classifier" "atrium_json_classifier" {
  name           = "atrium_json_classifier"
  json_classifier {
    json_path = "$.data[*]"
  }
}

resource "aws_iam_role" "atrium_glue_role" {
  name = "atrium-glue-role"

  inline_policy {
    name   = "Atrium-S3-Policies"
    policy = data.aws_iam_policy_document.dms_dv_s3_iam_policy_document.json
  }

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
  role       = aws_iam_role.atrium_glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

#data "aws_iam_policy_document" "atrium_glue_principal_iam_policy_document" {
#  statement {
#    effect = "Allow"
#    actions = ["sts:AssumeRole"]
#    principals {
#      service = "glue.amazonaws.com"
#    }
#  }
#}

data "aws_iam_policy_document" "atrium_s3_iam_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.data_store.arn}/*",
       aws_s3_bucket.data_store.arn
    ]
  }
}
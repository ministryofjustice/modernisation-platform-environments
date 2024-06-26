resource "aws_glue_catalog_database" "atrium_unstructured_db" {
  name = "atrium_unstructured"
}

resource "aws_glue_crawler" "atrium_unstructured_crawler" {
  name         = "atrium_unstructured_crawler"
  role         = aws_iam_role.atrium_glue_role.arn
  database_name = aws_glue_catalog_database.atrium_unstructured_db.name

  s3_target {
    path = "s3://em-data-store-20240131094334066000000004/g4s/dev_access/2024-02-16/json/"
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

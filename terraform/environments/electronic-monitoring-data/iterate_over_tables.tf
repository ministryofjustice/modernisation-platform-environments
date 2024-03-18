#------------------------------------------------------------------------------
# Lambda function and IAM role definition
#------------------------------------------------------------------------------
data "archive_file" "get_table_names" {
  type        = "zip"
  source_file = "get_table_names.py"
  output_path = "get_table_names.zip"
}

resource "aws_lambda_function" "get_table_names" {
  filename      = "get_table_names.zip"
  function_name = "get-all-table-names"
  role          = aws_iam_role.get_table_names_lambda.arn
  handler       = "get_table_names.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 4096
  timeout       = 900
  layers = [aws_lambda_layer_version.get_table_names_lambda_layer.arn]
}

resource "aws_iam_role" "get_table_names_lambda" {
  name                = "get-table-names-iam"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "get_glue_table_names_policy" {
    statement {
      sid    = "VPCConfig"
      effect = "Allow"
      actions = [
        "glue:GetTables",
        "glue:GetDatabases"
      ]
      resources = ["*"]
  }
}

resource "aws_iam_role_policy" "get_table_names_lambda" {
    name = "get-table-names-iam-policy"
    role = aws_iam_role.get_table_names_lambda.id
    policy = data.aws_iam_policy_document.get_glue_table_names_policy.json
}

resource "aws_lambda_permission" "get_table_names_lambda" {
  statement_id  = "GetTableNamesGlueSchema"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_table_names.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.rds_to_parquet.arn
}

#-----------------------------------------------------------------------------
# Lambda layer for the above lambda
#------------------------------------------------------------------------------


#define variables
locals {
  table_names_layer_path = "get_table_names_lambda_layer"
  layer_zip_name    = "${local.table_names_layer_path}.zip"
  requirements_name = "requirements.txt"
  requirements_path = "${path.module}/${local.table_names_layer_path}/${local.requirements_name}"
}

# create zip file from requirements.txt. Triggers only when the file is updated
resource "null_resource" "get_table_names_lambda_layer" {
  triggers = {
    requirements = filesha1(local.requirements_path)
  }
  # the command to install python and dependencies to the machine and zips
  provisioner "local-exec" {
    command = <<EOT
      cd ${local.table_names_layer_path}
      rm -rf python
      mkdir python
      pip install \
      --platform manylinux2014_x86_64 \
      --target=python \
      --implementation cp \
      --python-version 3.12 \
      --only-binary=:all: --upgrade \
      -r ${local.requirements_name}
      zip -r ${local.layer_zip_name} python/
    EOT
  }
}

# create lambda layer from s3 object
resource "aws_lambda_layer_version" "get_table_names_lambda_layer" {
  s3_bucket           = aws_s3_bucket.rds_to_parquet.id
  s3_key              = aws_s3_object.lambda_layer_zip.key
  layer_name          = local.table_names_layer_path
  compatible_runtimes = ["python3.12"]
  skip_destroy        = true
  depends_on          = [aws_s3_object.lambda_layer_zip] # triggered only if the zip file is uploaded to the bucket
}


# upload zip file to s3
resource "aws_s3_object" "lambda_layer_zip" {
  bucket     = aws_s3_bucket.rds_to_parquet.id
  key        = "lambda_layers/${local.table_names_layer_path}/${local.layer_zip_name}"
  source     = "${local.table_names_layer_path}/${local.layer_zip_name}"
  depends_on = [null_resource.get_table_names_lambda_layer] # triggered only if the zip file is created
}





# resource "aws_sfn_state_machine" "sfn_state_machine" {
#   name     = "my-state-machine"
#   role_arn = aws_iam_role.iam_for_sfn.arn
#   publish  = true
#   type     = "EXPRESS"
#   definition = <<EOF
# {
#   "Comment": "Orchestration to run Glue job on all tables in a Glue schema",
#   "StartAt": "StartCrawler",
#   "States": {
#     "StartCrawler": {
#       "Type": "Task",
#       "Next": "ListTables",
#       "Parameters": {
#         "Name": "MyData"
#       },
#       "Resource": "arn:aws:states:::aws-sdk:glue:startCrawler"
#     },
#     "ListTables": {
#       "Type": "Task",
#       "Resource": "arn:aws:lambda:REGION:ACCOUNT_ID:function:ListTablesLambdaFunction",
#       "Next": "TriggerGlueJobs",
#       "Catch": [
#         {
#           "ErrorEquals": [
#             "States.ALL"
#           ],
#           "Next": "ErrorState"
#         }
#       ]
#     },
#     "TriggerGlueJobs": {
#       "Type": "Map",
#       "ItemsPath": "$.tableNames",
#       "Iterator": {
#         "StartAt": "Glue StartJobRun",
#         "States": {
#           "Glue StartJobRun": {
#             "Type": "Task",
#             "Resource": "arn:aws:states:::glue:startJobRun.sync",
#             "Parameters": {
#               "JobName": "myJobName"
#             },
#             "End": true
#           }
#         }
#       },
#       "Next": "Finish"
#     },
#     "Finish": {
#       "Type": "Succeed"
#     },
#     "ErrorState": {
#       "Type": "Fail"
#     }
#   }
# }
# EOF
# }


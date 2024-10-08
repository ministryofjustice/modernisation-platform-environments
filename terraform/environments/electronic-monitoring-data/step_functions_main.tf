resource "aws_sfn_state_machine" "athena_layer" {
  name     = "athena-layer"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode(
    {
      "StartAt" : "GetMetadataList",
      "States" : {
        "GetMetadataList" : {
          "Type" : "Task",
          "Resource" : "${module.get_metadata_from_rds_lambda.lambda_function_arn}",
          "ResultPath" : "$.metadata_list",
          "Next" : "LoopThroughMetadataList"
        },
        "LoopThroughMetadataList" : {
          "Type" : "Map",
          "ItemsPath" : "$.metadata_list.metadata_list",
          "MaxConcurrency" : 4,
          "Iterator" : {
            "StartAt" : "CreateAthenaTable",
            "States" : {
              "CreateAthenaTable" : {
                "Type" : "Task",
                "Resource" : "${module.create_athena_table.lambda_function_arn}",
                "ResultPath" : "$.result",
                "End" : true
              }
            }
          },
          "End" : true
        }
      }
    }
  )

}

resource "aws_kms_key" "athena_layer_step_functions_log_key" {
  description         = "KMS key for encrypting Step Functions logs for athena_layer"
  enable_key_rotation = true

  policy = jsonencode(
    {
      "Id" : "key-default",
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Enable IAM User Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${local.env_account_id}:root"
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "Enable log service Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "logs.eu-west-2.amazonaws.com"
          },
          "Action" : [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_cloudwatch_log_group" "athena_layer" {
  name              = "/aws/vendedlogs/states/athena_layer"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.athena_layer_step_functions_log_key.arn
}
# ------------------------------------------
# Send Database to AP
# ------------------------------------------

resource "aws_sfn_state_machine" "send_database_to_ap" {
  name     = "send_database_to_ap_layer"
  role_arn = aws_iam_role.send_database_to_ap.arn

  definition = jsonencode(
    {
      "StartAt" : "GetValidatedTableList",
      "States" : {
        "GetValidatedTableList" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::athena:startQueryExecution.sync",
          "Parameters" : {
            "QueryString.$" : "States.Format('SELECT database_name, split(validation_msg, \\' - \\', 2)[1] as table_name FROM \"dms_data_validation\".\"glue_df_output\" WHERE validation_msg like \\'%Validated%\\' and database_name = \\'{}\\' and table_to_ap = \\'False\\'', $.db_name)",
            "WorkGroup" : "${aws_athena_workgroup.default.name}",
          },
          "ResultPath" : "$.queryResult",
          "Next" : "GetQueryResults"
        },
        "GetQueryResults" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::athena:getQueryResults",
          "Parameters" : {
            "QueryExecutionId.$" : "$.queryResult.QueryExecution.QueryExecutionId"
          },
          "ResultPath" : "$.queryOutput",
          "Next" : "QueryOutputToList"
        },
        "QueryOutputToList" : {
          "Type" : "Task",
          "Resource" : "${module.query_output_to_list.lambda_function_arn}",
          "ResultPath" : "$.queryOutputList",
          "Next" : "LoopThroughTables"
        },
        "LoopThroughTables" : {
          "Type" : "Map",
          "ItemsPath" : "$.queryOutputList",
          "MaxConcurrency" : 4,
          "Iterator" : {
            "StartAt" : "GetTableFileNames",
            "States" : {
              "GetTableFileNames" : {
                "Type" : "Task",
                "Resource" : "${module.get_file_keys_for_table.lambda_function_arn}",
                "ResultPath" : "$.fileKeys",
                "Next" : "LoopThroughFileKeys"
              },
              "LoopThroughFileKeys" : {
                "Type" : "Map",
                "ItemsPath" : "$.fileKeys",
                "MaxConcurrency" : 4,
                "OutputPath" : "$[0].dbInfo",
                "Iterator" : {
                  "StartAt" : "SendTableToAp",
                  "States" : {
                    "SendTableToAp" : {
                      "Type" : "Task",
                      "Resource" : "${module.send_table_to_ap.lambda_function_arn}",
                      "InputPath" : "$",
                      "ResultPath" : "$.dbInfo",
                      "End" : true
                    }
                  }
                }
                "Next" : "UpdateLogTable"
              },
              "UpdateLogTable" : {
                "Type" : "Task",
                "Resource" : "${module.update_log_table.lambda_function_arn}",
                "End" : true
              }
            },
          }
          "Next" : "FixLogTable"
        },
        "FixLogTable" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::athena:startQueryExecution.sync",
          "Parameters" : {
            "QueryString" : "MSCK REPAIR TABLE dms_data_validation.glue_df_output",
            "WorkGroup" : "${aws_athena_workgroup.default.name}"
          },
          "End" : true
        }
      }
    }
  )
}

resource "aws_kms_key" "send_database_to_ap_step_functions_log_key" {
  description         = "KMS key for encrypting Step Functions logs for send_database_to_ap"
  enable_key_rotation = true

  policy = jsonencode(
    {
      "Id" : "key-default",
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Enable IAM User Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${local.env_account_id}:root"
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "Enable log service Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "logs.eu-west-2.amazonaws.com"
          },
          "Action" : [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_cloudwatch_log_group" "send_database_to_ap" {
  name              = "/aws/vendedlogs/states/send_database_to_ap"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.send_database_to_ap_step_functions_log_key.arn
}

data "aws_iam_policy_document" "trigger_unzip_lambda" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      module.unzip_single_file.lambda_function_arn,
      module.unzipped_presigned_url.lambda_function_arn
    ]
  }
}

resource "aws_iam_policy" "trigger_unzip_lambda" {
  name   = "trigger_unzip_lambda"
  policy = data.aws_iam_policy_document.trigger_unzip_lambda.json
}

module "get_zipped_file" {
  source         = "./modules/step_function"
  name           = "get_zipped_file"
  iam_policies   = tomap({ "trigger_unzip_lambda" = aws_iam_policy.trigger_unzip_lambda })
  variable_dictionary = tomap(
    {
      "unzip_file_name"            = module.unzip_single_file.lambda_function_name,
      "pre_signed_url_lambda_name" = module.unzipped_presigned_url.lambda_function_name
    }
  )
}

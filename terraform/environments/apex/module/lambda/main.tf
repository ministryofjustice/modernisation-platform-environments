



data "archive_file" "lambda_dbsnapshot" {
  count = 2
  type        = "zip"
  source_file = var.source_file[count.index]
  output_path = var.output_path[count.index]
}

# data "archive_file" "lambda_dbconnect" {
#   type        = "zip"
#   source_file = "dbconnect.js"
#   output_path = "connectDBFunction.zip"
# }

# data "archive_file" "lambda_delete_deletesnapshots" {
#   type        = "zip"
#   source_file = "deletesnapshots.py"
#   output_path = "DeleteEBSPendingSnapshots.zip"
# }

resource "aws_lambda_function" "snapshotDBFunction" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.

  count         = 2
  filename      = var.filename[count.index]
  function_name = var.function_name[count.index]
  role          = var.role
  handler       = var.handler[count.index]

  source_code_hash = data.archive_file.lambda_dbsnapshot[count.index].output_base64sha256

  runtime = var.runtime[count.index]

#   environment {
#     variables = {
#       foo = "bar"
#     }
#   }
}


data "archive_file" "lambda_dbsnapshot" {
  count = 3
  type        = "zip"
  source_file = var.source_file[count.index]
  output_path = var.output_path[count.index]
}


resource "aws_lambda_function" "snapshotDBFunction" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.

  count         = 3
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


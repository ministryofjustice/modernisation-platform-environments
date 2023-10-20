

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

# resource "aws_cloudwatch_event_rule" "mon_sun" {
#     name = "laa-createSnapshotRule-LWN8E1LNHFJR"
#     description = "Fires every five minutes"
#     schedule_expression = "cron(15 11 ? * MON-SUN *)"
    
    
# }

# resource "aws_cloudwatch_event_target" "check_mon_sun" {
#     count = 1
#     rule = aws_cloudwatch_event_rule.mon_sun.name
#     arn = "${aws_lambda_function.snapshotDBFunction[0].arn}"
#     input = {"appname": "apex Database Server"}
  
# }

# resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_sun" {
#     count = 1
#     statement_id = "AllowExecutionFromCloudWatch"
#     action = "lambda:InvokeFunction"
#     function_name = aws_lambda_function.snapshotDBFunction[0].function_name
#     principal = "events.amazonaws.com"
#     source_arn = aws_cloudwatch_event_rule.mon_sun.arn
# }
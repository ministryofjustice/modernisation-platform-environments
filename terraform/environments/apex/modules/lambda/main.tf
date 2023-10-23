


resource "aws_security_group" "lambdasg" {
  name        = var.security_grp_name
  description = "APEX Lambda Security Group"
  vpc_id      = var.vpc_id


  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "archive_file" "lambda_dbsnapshot" {
  count = 1
  type        = "zip"
  source_file = var.source_file[count.index]
  output_path = var.output_path[count.index]
}


resource "aws_lambda_function" "snapshotDBFunction" {
  count         = 1
  filename      = var.filename[count.index]
  function_name = var.function_name[count.index]
  role          = var.role
  handler       = var.handler[count.index]
  source_code_hash = data.archive_file.lambda_dbsnapshot[count.index].output_base64sha256
  runtime = var.runtime[count.index]
  s3_bucket = var.lamdbabucketname
  s3_key = var.key
  
  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
   vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids = var.subnet_ids
  }
 tags = var.tags
}

resource "aws_cloudwatch_event_rule" "mon_sun" {
    name = "laa-createSnapshotRule-LWN8E1LNHFJR"
    description = "Fires every five minutes"
    schedule_expression = "cron(32 14 ? * MON-SUN *)"
    
    
}

resource "aws_cloudwatch_event_target" "check_mon_sun" {
    count = 1
    rule = aws_cloudwatch_event_rule.mon_sun.name
    arn = "${aws_lambda_function.snapshotDBFunction[0].arn}"
    input =jsonencode({"appname": "apex Database Server"})

}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_sun" {
    count = 1
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.snapshotDBFunction[0].function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.mon_sun.arn
}
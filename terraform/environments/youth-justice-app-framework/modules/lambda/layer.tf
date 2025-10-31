# Lambda Layer might not be needed right now
#resource "aws_lambda_layer_version" "lambda_layer" {
#  count what?
#  layer_name               = "${var.project_name}-${var.environment}-layer"
#  s3_bucket                = aws_s3_bucket.lambda_payment_load.bucket
#  s3_key                   = aws_s3_object.lambda_layer_s3.key
#  compatible_runtimes      = ["python3.10"]
#  compatible_architectures = ["x86_64"]
#  description              = "Lambda Layer for ${var.project_name}"
#
#  depends_on = [aws_s3_object.lambda_layer_s3]
#}

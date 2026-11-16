# CloudFront access logs delivered to CloudWatch Logs.
# Delivery source/destination must be created in us-east-1, as CloudFront is managed from that region.

/*

resource "aws_cloudwatch_log_group" "cloudfront" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS" - fix later us east-1 region issues
  provider          = aws.us-east-1
  name              = "/aws/cloudfront/${var.cloudfront_route53_record_name}-${var.environment}"
  retention_in_days = 400
  tags              = var.tags
}

resource "aws_cloudwatch_log_delivery_source" "cloudfront" {
  provider     = aws.us-east-1
  name         = "${var.cloudfront_route53_record_name}-${var.environment}-cloudfront"
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.external.arn
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront" {
  provider      = aws.us-east-1
  name          = "${var.cloudfront_route53_record_name}-${var.environment}-cloudfront"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.cloudfront.arn
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_delivery" "cloudfront" {
  provider                 = aws.us-east-1
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront.arn
}
*/
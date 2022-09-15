output "s3_kms_arn" {
  description = "Amazon S3 Resource KmS KEY (ARN)"
  value       = aws_kms_key.s3.arn
}
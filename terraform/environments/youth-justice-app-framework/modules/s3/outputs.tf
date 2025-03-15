output "aws_s3_bucket_arn" {
  description = "List of arn for the created s3 buckets created in the same odring as the names were input."
  value       = [for bucket in aws_s3_bucket.default : bucket.arn]
}

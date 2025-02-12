output "bucket" {
  value = module.this-bucket.bucket
  description = "Direct aws_s3_bucket resource with all attributes"
}

output "bucket" {
  value = module.this-bucket.bucket.default
  description = "Direct aws_s3_bucket resource with all attributes"
}

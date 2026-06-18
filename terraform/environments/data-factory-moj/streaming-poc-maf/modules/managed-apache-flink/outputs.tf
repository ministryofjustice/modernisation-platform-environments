output "config" {
  value = var.config_property_group
}

output "bucket" {
  value = data.aws_s3_bucket.source_bucket
}

output "object" {
  value = data.aws_s3_object.source_file
}

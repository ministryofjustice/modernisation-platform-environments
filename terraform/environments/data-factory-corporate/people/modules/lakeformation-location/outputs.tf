output "location_arn" {
  description = "Registered bucket or prefix ARN, available after registration."
  value       = aws_lakeformation_resource.s3_location.arn
}
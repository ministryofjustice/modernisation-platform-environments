output "chaps_instances_details" {
  description = "Details of the fetched chaps instances"
  value       = data.aws_instances.chaps_instances
}

output "chaps_instances_ips" {
  value = data.aws_instances.chaps_instances[*].private_ips
}

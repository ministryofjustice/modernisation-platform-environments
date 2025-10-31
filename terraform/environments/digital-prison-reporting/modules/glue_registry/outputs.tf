output "registry_name" {
  description = "Registry Name"
  value       = aws_glue_registry.glue_registry[0].id
}

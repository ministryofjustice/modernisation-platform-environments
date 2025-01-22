output "rds_cluster_endpoint" {
  description = "The endpoint of the Aurora cluster"
  value       = module.aurora.cluster_endpoint
}

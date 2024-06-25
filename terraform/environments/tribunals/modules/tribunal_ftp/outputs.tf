output "tribunals_lb_sc_id_sftp" {
  description = "LB Security Group Id"
  value       = module.ecs_loadbalancer.tribunals_lb_sc_id_sftp
}

output "tribunals_lb_ftp" {
  description = "SFTP LB"
  value       = module.ecs_loadbalancer.tribunals_lb_ftp
}


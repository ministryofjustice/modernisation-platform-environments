output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "iam_role_arn" {
  value = module.analytical_platform_ui_service_role.iam_role_arn
}

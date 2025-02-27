output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "iam_role_arn" {
  value = module.analytical_platform_ui_service_role.iam_role_arn
}

output "arn" {
  value = module.managed_prometheus_kms_access_iam_policy.arn
}

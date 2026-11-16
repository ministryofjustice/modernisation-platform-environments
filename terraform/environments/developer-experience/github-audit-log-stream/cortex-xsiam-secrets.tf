data "aws_secretsmanager_secret_version" "cortex_xsiam_workload_identity" {
  count = local.is-production ? 1 : 0

  secret_id = "${local.component_name}/cortex-xsiam-workload-identity"
}
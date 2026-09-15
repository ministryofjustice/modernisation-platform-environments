data "aws_secretsmanager_secret" "cortex_xsiam_workload_identity" {
  count = local.is-production ? 1 : 0

  name = "${local.component_name}/cortex-xsiam-workload-identity"
}

data "aws_secretsmanager_secret_version" "cortex_xsiam_workload_identity" {
  count = local.is-production ? 1 : 0

  secret_id = data.aws_secretsmanager_secret.cortex_xsiam_workload_identity[0].id
}
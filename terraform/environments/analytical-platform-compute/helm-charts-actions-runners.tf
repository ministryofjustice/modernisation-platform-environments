/* create-a-derived-table */

data "aws_secretsmanager_secret_version" "actions_runners_create_a_derived_table" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_create_a_derived_table_secret[0].secret_id
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.317.0"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        replicaCount         = 2
        github_organisation  = "moj-analytical-services"
        github_repository    = "create-a-derived-table"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_create_a_derived_table[0].secret_string
        github_runner_labels = "analytical-platform"
        eks_role_arn         = "arn:aws:iam::593291632749:role/create-a-derived-table"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_dpr" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-dpr"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.317.0"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        replicaCount         = 1
        github_organisation  = "moj-analytical-services"
        github_repository    = "create-a-derived-table"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_create_a_derived_table[0].secret_string
        github_runner_labels = "digital-prison-reporting"
        eks_role_arn         = "arn:aws:iam::972272129531:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

/* Airflow */

data "aws_secretsmanager_secret_version" "actions_runners_airflow" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_airflow[0].secret_id
}

resource "helm_release" "actions_runner_mojas_airflow" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-airflow"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.317.0"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow/values.yml.tftpl",
      {
        replicaCount         = 2
        github_organisation  = "moj-analytical-services"
        github_repository    = "airflow"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_airflow[0].secret_string
        github_runner_labels = "analytical-platform"
        eks_role_arn         = "arn:aws:iam::593291632749:role/data-iam-creator"
      }
    )
  ]
}

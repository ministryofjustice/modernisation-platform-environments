/* Airflow */

data "aws_secretsmanager_secret_version" "actions_runners_airflow" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_airflow_secret[0].secret_id
}

resource "helm_release" "actions_runner_mojas_airflow" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-airflow"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.320.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow/values.yml.tftpl",
      {
        github_organisation  = "moj-analytical-services"
        github_repository    = "airflow"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_airflow[0].secret_string
        github_runner_labels = "analytical-platform"
        eks_role_arn         = "arn:aws:iam::593291632749:role/data-iam-creator"
      }
    )
  ]
}

/* airflow-create-a-pipeline */

data "aws_secretsmanager_secret_version" "actions_runners_airflow_create_a_pipeline" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  secret_id = module.actions_runners_airflow_create_a_pipeline_secret[0].secret_id
}

resource "helm_release" "actions_runner_mojas_airflow_create_a_pipeline" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-airflow-create-a-pipeline"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.320.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow-create-a-pipeline/values.yml.tftpl",
      {
        github_organisation  = "moj-analytical-services"
        github_repository    = "airflow-create-a-pipeline"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_airflow_create_a_pipeline[0].secret_string
        github_runner_labels = "analytical-platform"
      }
    )
  ]
}

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
  version    = "2.320.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
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
  version    = "2.320.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_organisation  = "moj-analytical-services"
        github_repository    = "create-a-derived-table"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_create_a_derived_table[0].secret_string
        github_runner_labels = "digital-prison-reporting"
        eks_role_arn         = "arn:aws:iam::004723187462:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_dpr_pp" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-dpr-pp"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.320.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_organisation  = "moj-analytical-services"
        github_repository    = "create-a-derived-table"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_create_a_derived_table[0].secret_string
        github_runner_labels = "digital-prison-reporting-pp"
        eks_role_arn         = "arn:aws:iam::972272129531:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

# ---------------------------------------------------
# EM test account
# ---------------------------------------------------
resource "helm_release" "actions_runner_mojas_create_a_derived_table_emds_test" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-emds-test"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.320.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_organisation  = "moj-analytical-services"
        github_repository    = "create-a-derived-table"
        github_token         = data.aws_secretsmanager_secret_version.actions_runners_create_a_derived_table[0].secret_string
        github_runner_labels = "electronic-monitoring-data-test"
        eks_role_arn         = "arn:aws:iam::396913731313:role/emds-test-data-api-cross-account-role"
      }
    )
  ]
}
/* airflow */

resource "helm_release" "actions_runner_mojas_airflow" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-airflow"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.323.0-2"
  chart      = "actions-runner"
  namespace  = data.kubernetes_namespace.actions_runner.metadata.name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_token_apc_self_hosted_runners_github_app[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_token_apc_self_hosted_runners_github_app[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "airflow"
        github_runner_labels       = "analytical-platform"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/data-iam-creator"
      }
    )
  ]
}

/* airflow-create-a-pipeline */

resource "helm_release" "actions_runner_mojas_airflow_create_a_pipeline" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-airflow-create-a-pipeline"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.323.0-2"
  chart      = "actions-runner"
  namespace  = data.kubernetes_namespace.actions_runner.metadata.name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow-create-a-pipeline/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_token_apc_self_hosted_runners_github_app[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_token_apc_self_hosted_runners_github_app[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "airflow-create-a-pipeline"
        github_runner_labels       = "analytical-platform"
      }
    )
  ]
}

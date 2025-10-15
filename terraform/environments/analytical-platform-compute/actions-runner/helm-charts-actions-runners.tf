/* airflow */

resource "helm_release" "actions_runner_mojas_airflow" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-airflow"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
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
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/airflow-create-a-pipeline/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "airflow-create-a-pipeline"
        github_runner_labels       = "analytical-platform"
      }
    )
  ]
}

/* create-a-derived-table */

resource "helm_release" "actions_runner_mojas_create_a_derived_table" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "analytical-platform"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/create-a-derived-table"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_non_spot" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-non-spot"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "analytical-platform-non-spot"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/create-a-derived-table"
      }
    )
  ]
  set {
    name  = "ephemeral.karpenter.nodePool"
    value = "general-on-demand"
  }
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_sandbox_a" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-cadt-sandbox-a"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "analytical-platform-sandbox-a"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-engineering-sandboxa"]}:role/create-a-derived-table"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_sandbox_a_non_spot" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-cadt-sandbox-a-non-spot"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "analytical-platform-sandbox-a-non-spot"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/create-a-derived-table"
      }
    )
  ]
  set {
    name  = "ephemeral.karpenter.nodePool"
    value = "general-on-demand"
  }
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_dpr" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-dpr"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "digital-prison-reporting"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-production"]}:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_dpr_pp" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-dpr-pp"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "digital-prison-reporting-pp"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-preproduction"]}:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_dpr_test" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-dpr-test"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "digital-prison-reporting-test"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-test"]}:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_dpr_dev" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-dpr-dev"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "digital-prison-reporting-dev"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-development"]}:role/dpr-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_emds_test" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-emds-test"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "electronic-monitoring-data-test"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["electronic-monitoring-data-test"]}:role/test-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_emds_pp" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-emds-pp"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "electronic-monitoring-data-preprod"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["electronic-monitoring-data-preproduction"]}:role/preprod-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_emds" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-create-a-derived-table-emds"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "electronic-monitoring-data"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["electronic-monitoring-data-production"]}:role/prod-data-api-cross-account-role"
      }
    )
  ]
}

resource "helm_release" "actions_runner_mojas_create_a_derived_table_property_dev" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-mojas-cadt-property-dev"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/create-a-derived-table/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "moj-analytical-services"
        github_repository          = "create-a-derived-table"
        github_runner_labels       = "property-dev"
        eks_role_arn               = "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/create-a-derived-table"
      }
    )
  ]
}

/* data-catalogue */

resource "helm_release" "actions_runner_moj_data_catalogue" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  /* https://github.com/ministryofjustice/analytical-platform-actions-runner */
  name       = "actions-runner-moj-data-catalogue"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "2.328.0-1"
  chart      = "actions-runner"
  namespace  = kubernetes_namespace.actions_runners[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/actions-runners/data-catalogue/values.yml.tftpl",
      {
        github_app_application_id  = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["app_id"]
        github_app_installation_id = jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_string)["installation_id"]
        github_organisation        = "ministryofjustice"
        github_repository          = "data-catalogue"
        github_runner_labels       = "analytical-platform"
      }
    )
  ]
}

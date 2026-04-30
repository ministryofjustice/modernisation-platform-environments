# ------------------------------------------
# Unzip Files
# ------------------------------------------

module "get_zipped_file_api" {
  source       = "./modules/step_function"
  name         = "get_zipped_file_api"
  iam_policies = tomap({ "trigger_unzip_lambda" = aws_iam_policy.trigger_unzip_lambda })
  variable_dictionary = tomap(
    {
      "unzip_file_name"            = module.unzip_single_file.lambda_function_name,
      "pre_signed_url_lambda_name" = module.unzipped_presigned_url.lambda_function_name
    }
  )
  type = "EXPRESS"
}

# ------------------------------------------
# DMS Validation Step Function
# ------------------------------------------

module "dms_validation_step_function" {
  count = local.is-development || local.is-production || local.is-preproduction ? 1 : 0

  source       = "./modules/step_function"
  name         = "dms_validation"
  iam_policies = tomap({ "dms_validation_step_function_policy" = aws_iam_policy.dms_validation_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "dms_retrieve_metadata" = module.dms_retrieve_metadata[0].lambda_function_name,
      "dms_validation"        = module.dms_validation[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# Data Cut Back Step Function
# ------------------------------------------

module "data_cutback_step_function" {
  count = local.is-development || local.is-production ? 1 : 0

  source       = "./modules/step_function"
  name         = "data_cutback"
  iam_policies = tomap({ "data_cutback_step_function_policy" = aws_iam_policy.data_cutback_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "data_cutback" = module.data_cutback[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# Ears and Sars Step funtion
# ------------------------------------------

module "ears_sars_step_function" {
  count = local.is-development || local.is-preproduction ? 1 : 0

  source       = "./modules/step_function"
  name         = "ears_sars"
  iam_policies = tomap({ "ears_sars_step_function_policy" = aws_iam_policy.ears_sars_step_function_policy[0] })
  variable_dictionary = tomap(
    {
      "ears_sars_request" = module.ears_sars_request[0].lambda_function_name,
    }
  )
  type = "STANDARD"
}


# ------------------------------------------
# GDPR Step Function
# ------------------------------------------

locals {
  gdpr_databases = local.is-production ? [
    "buddi_buddi_local",
    "buddi_buddi",
    "capita_alcohol_monitoring",
    "capita_blob_storage",
    "civica_orca",
    "g4s_atrium",
    "g4s_atrium_unstructured",
    "g4s_atv",
    "g4s_cap_dw",
    "g4s_centurion",
    "g4s_centurion_test",
    "g4s_emsys_mvp",
    "g4s_emsys_tpims",
    "g4s_fep",
    "g4s_gps",
    "g4s_integrity",
    "g4s_lcm_archive",
    "g4s_lcm",
    "g4s",
    "g4s_rf_hours",
    "g4s_tasking",
    "scram_alcohol_monitoring"] : local.is-preproduction ? [
    "buddi_buddi_local_preprod",
    "buddi_buddi_preprod",
    "capita_alcohol_monitoring_preprod",
    "capita_blob_storage_preprod",
    "civica_orca_preprod",
    "g4s_atrium_preprod",
    "g4s_atrium_unstructured_preprod",
    "g4s_atv_preprod",
    "g4s_cap_dw_preprod",
    "g4s_centurion_preprod",
    "g4s_centurion_test_preprod",
    "g4s_emsys_mvp_preprod",
    "g4s_emsys_tpims_preprod",
    "g4s_fep_preprod",
    "g4s_gps_preprod",
    "g4s_integrity_preprod",
    "g4s_lcm_archive_preprod",
    "g4s_lcm_preprod",
    "g4s_preprod",
    "g4s_rf_hours_preprod",
    "g4s_tasking_preprod",
    "scram_alcohol_monitoring_preprod"
  ] : local.is-development ? ["test"] : []

}
module "gdpr_deletion_step_function" {
  count        = local.is-development || local.is-preproduction ? 1 : 0
  source       = "./modules/step_function"
  name         = "gdpr_deletion"
  iam_policies = tomap({ "gdpr_deletion_step_function_policy" = aws_iam_policy.gdpr_delete_iam_policy[0] })
  variable_dictionary = tomap(
    {
      "cluster_arn"            = aws_ecs_cluster.emds-gdpr-cluster[0].arn
      "task_definition_family" = aws_ecs_task_definition.emds-gdpr-structured-data-deletion[0].family
      "container_name"         = "emds_gdpr_structured_data_deletion_job"
      "security_groups_json"   = jsonencode([aws_security_group.ecs_generic.id])
      "subnets_json"           = jsonencode(data.aws_subnets.shared-private.ids)
      "athena_output_bucket"   = "s3://${module.s3-athena-bucket.bucket.id}/output/"
      "gdpr_databases"         = jsonencode(local.gdpr_databases)
    }
  )
  type = "STANDARD"
}

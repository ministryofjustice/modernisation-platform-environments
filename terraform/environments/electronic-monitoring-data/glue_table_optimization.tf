locals {
  database_to_optimize = [
    "allied_mdss",
    "serco_fms",
    "staged_mdss",
    "serco_fms_deduped",
    "serco_fms_curated",
    "staging_mdss",
    "staging_fms",
    "intermediate_fms",
    "intermediate_mdss",
    "datamart",
    "derived",
    "analysis",
    "acquisitive_crime",
    "data_insights",
  ]

  # Default settings applied to all tables unless overridden per-table.
  # Set a value to null to use the provider default.
  table_optimizer_defaults = {
    snapshot_retention_period_in_days      = 7
    number_of_snapshots_to_retain          = 3
    orphan_file_retention_period_in_days   = 7
    retention_run_rate_in_hours            = 24
    orphan_file_deletion_run_rate_in_hours = 24
  }

  # Per-table overrides: supply any subset of the keys from
  # table_optimizer_defaults to override that table's settings.
  # Use an empty map {} for tables that should use all defaults.
  tables_to_optimize = {
    "allied_mdss" = {
      "_dlt_loads" = {
        snapshot_retention_period_in_days      = 3
        number_of_snapshots_to_retain          = 3
        orphan_file_retention_period_in_days   = 1
        retention_run_rate_in_hours            = 3
        orphan_file_deletion_run_rate_in_hours = 3
      }
      "_dlt_pipeline_state" = {}
      "_dlt_version"        = {}
      "curfew"              = {}
      "curfew__rule"        = {}
      "curfew__zone"        = {}
      "device"              = {}
      "device_activation"   = {}
      "event"               = {}
      "person"              = {}
      "position"            = {}
    }
    "serco_fms" = {
      "_dlt_loads" = {
        snapshot_retention_period_in_days      = 3
        number_of_snapshots_to_retain          = 3
        orphan_file_retention_period_in_days   = 1
        retention_run_rate_in_hours            = 3
        orphan_file_deletion_run_rate_in_hours = 3
      }
      "_dlt_pipeline_state"                                  = {}
      "_dlt_version"                                         = {}
      "alm_asset"                                            = {}
      "asmt_assessment_instance"                             = {}
      "asmt_assessment_instance_question"                    = {}
      "alm_hardware"                                         = {}
      "alm_stockroom"                                        = {}
      "alm_transfer_order"                                   = {}
      "asmt_metric"                                          = {}
      "asmt_metric_result"                                   = {}
      "cmdb_hardware_product_model"                          = {}
      "cmn_location"                                         = {}
      "cmn_schedule"                                         = {}
      "cmn_schedule_span"                                    = {}
      "cmn_skill_level"                                      = {}
      "csm_consumer"                                         = {}
      "customer_account"                                     = {}
      "customer_contact"                                     = {}
      "interaction"                                          = {}
      "m2m_kb_task"                                          = {}
      "problem"                                              = {}
      "sm_asset_usage"                                       = {}
      "sm_part_requirement"                                  = {}
      "sn_customerservice_task"                              = {}
      "sys_choice" = {}
      "sys_dictionary"                                       = {}
      "sys_db_object"                                        = {}
      "wm_crew"                                              = {}
      "wm_crew_member"                                       = {}
      "wm_crew_skill"                                        = {}
      "wm_order"                                             = {}
      "wm_questionnaire"                                     = {}
      "wm_task"                                              = {}
      "wm_work_type"                                         = {}
      "x_serg2_ems_am_cmdb_ci_alcohol_monitoring_device"     = {}
      "x_serg2_ems_am_cmdb_ci_home_monitoring_unit"          = {}
      "x_serg2_ems_am_cmdb_ci_gps_monitoring_device"         = {}
      "x_serg2_ems_am_cmdb_ci_monitoring_device"             = {}
      "x_serg2_ems_am_u_cmdb_ci_non_fitted_biometric_device" = {}
      "x_serg2_ems_csm_al_device_maintenance"                = {}
      "x_serg2_ems_csm_al_indication_fault"                  = {}
      "x_serg2_ems_csm_al_indication_noncompliance"          = {}
      "x_serg2_ems_csm_al_investigation_violation"           = {}
      "x_serg2_ems_csm_al_investigation_special"             = {}
      "x_serg2_ems_csm_al_notification_alert"                = {}
      "x_serg2_ems_csm_auto"                                 = {}
      "x_serg2_ems_csm_case"                                 = {}
      "x_serg2_ems_csm_complaints"                           = {}
      "x_serg2_ems_csm_compliments"                          = {}
      "x_serg2_ems_csm_enforcement_action"                   = {}
      "x_serg2_ems_csm_not_monitored"                        = {}
      "x_serg2_ems_csm_profile_device_wearer"                = {}
      "x_serg2_ems_csm_profile_sensitive"                    = {}
      "x_serg2_ems_csm_sr"                                   = {}
      "x_serg2_ems_csm_sr_info"                              = {}
      "x_serg2_ems_csm_sr_mo_existing"                       = {}
      "x_serg2_ems_csm_trials"                               = {}
      "x_serg2_ems_mom_commited_offence"                     = {}
      "x_serg2_ems_mom_mo"                                   = {}
      "x_serg2_ems_mom_monitoring_configuration"             = {}
      "x_serg2_ems_mom_mr"                                   = {}
      "x_serg2_ems_mom_violation"                            = {}
      "x_serg2_ems_mom_violation_mitigation"                 = {}
      "x_serg2_mdss_em_event_type"                           = {}
      "x_serg2_mdss_em_mdss_alert"                           = {}
    }
    "staged_mdss" = {
      "curfew_deduped" = {}
      "curfew_scd2" = {}
      "device_activation_deduped" = {}
      "device_activation_scd2" = {}
      "device_deduped" = {}
      "device_scd2" = {}
      "event" = {}
      "person_deduped" = {}
      "person_scd2" = {}
      "position" = {}
    }
    "serco_fms_deduped" = {
      "alm_asset"                                            = {}
      "asmt_assessment_instance"                             = {}
      "asmt_assessment_instance_question"                    = {}
      "alm_hardware"                                         = {}
      "alm_stockroom"                                        = {}
      "alm_transfer_order"                                   = {}
      "asmt_metric"                                          = {}
      "asmt_metric_result"                                   = {}
      "cmdb_hardware_product_model"                          = {}
      "cmn_location"                                         = {}
      "cmn_schedule"                                         = {}
      "cmn_schedule_span"                                    = {}
      "cmn_skill_level"                                      = {}
      "csm_consumer"                                         = {}
      "customer_account"                                     = {}
      "customer_contact"                                     = {}
      "interaction"                                          = {}
      "m2m_kb_task"                                          = {}
      "problem"                                              = {}
      "sm_asset_usage"                                       = {}
      "sm_part_requirement"                                  = {}
      "sn_customerservice_task"                              = {}
      "sys_choice" = {}
      "sys_dictionary"                                       = {}
      "sys_db_object"                                        = {}
      "wm_crew"                                              = {}
      "wm_crew_member"                                       = {}
      "wm_crew_skill"                                        = {}
      "wm_order"                                             = {}
      "wm_questionnaire"                                     = {}
      "wm_task"                                              = {}
      "wm_work_type"                                         = {}
      "x_serg2_ems_am_cmdb_ci_alcohol_monitoring_device"     = {}
      "x_serg2_ems_am_cmdb_ci_home_monitoring_unit"          = {}
      "x_serg2_ems_am_cmdb_ci_gps_monitoring_device"         = {}
      "x_serg2_ems_am_cmdb_ci_monitoring_device"             = {}
      "x_serg2_ems_am_u_cmdb_ci_non_fitted_biometric_device" = {}
      "x_serg2_ems_csm_al_device_maintenance"                = {}
      "x_serg2_ems_csm_al_indication_fault"                  = {}
      "x_serg2_ems_csm_al_indication_noncompliance"          = {}
      "x_serg2_ems_csm_al_investigation_violation"           = {}
      "x_serg2_ems_csm_al_investigation_special"             = {}
      "x_serg2_ems_csm_al_notification_alert"                = {}
      "x_serg2_ems_csm_auto"                                 = {}
      "x_serg2_ems_csm_case"                                 = {}
      "x_serg2_ems_csm_complaints"                           = {}
      "x_serg2_ems_csm_compliments"                          = {}
      "x_serg2_ems_csm_enforcement_action"                   = {}
      "x_serg2_ems_csm_not_monitored"                        = {}
      "x_serg2_ems_csm_profile_device_wearer"                = {}
      "x_serg2_ems_csm_profile_sensitive"                    = {}
      "x_serg2_ems_csm_sr"                                   = {}
      "x_serg2_ems_csm_sr_info"                              = {}
      "x_serg2_ems_csm_sr_mo_existing"                       = {}
      "x_serg2_ems_csm_trials"                               = {}
      "x_serg2_ems_mom_commited_offence"                     = {}
      "x_serg2_ems_mom_mo"                                   = {}
      "x_serg2_ems_mom_monitoring_configuration"             = {}
      "x_serg2_ems_mom_mr"                                   = {}
      "x_serg2_ems_mom_violation"                            = {}
      "x_serg2_ems_mom_violation_mitigation"                 = {}
      "x_serg2_mdss_em_event_type"                           = {}
      "x_serg2_mdss_em_mdss_alert"                           = {}
    }
    "serco_fms_curated" = {
      "alm_asset"                                            = {}
      "asmt_assessment_instance"                             = {}
      "asmt_assessment_instance_question"                    = {}
      "alm_hardware"                                         = {}
      "alm_stockroom"                                        = {}
      "alm_transfer_order"                                   = {}
      "asmt_metric"                                          = {}
      "asmt_metric_result"                                   = {}
      "cmdb_hardware_product_model"                          = {}
      "cmn_location"                                         = {}
      "cmn_schedule"                                         = {}
      "cmn_schedule_span"                                    = {}
      "cmn_skill_level"                                      = {}
      "csm_consumer"                                         = {}
      "customer_account"                                     = {}
      "customer_contact"                                     = {}
      "interaction"                                          = {}
      "m2m_kb_task"                                          = {}
      "problem"                                              = {}
      "sm_asset_usage"                                       = {}
      "sm_part_requirement"                                  = {}
      "sn_customerservice_task"                              = {}
      "sys_choice" = {}
      "sys_dictionary"                                       = {}
      "sys_db_object"                                        = {}
      "wm_crew"                                              = {}
      "wm_crew_member"                                       = {}
      "wm_crew_skill"                                        = {}
      "wm_order"                                             = {}
      "wm_questionnaire"                                     = {}
      "wm_task"                                              = {}
      "wm_work_type"                                         = {}
      "x_serg2_ems_am_cmdb_ci_alcohol_monitoring_device"     = {}
      "x_serg2_ems_am_cmdb_ci_home_monitoring_unit"          = {}
      "x_serg2_ems_am_cmdb_ci_gps_monitoring_device"         = {}
      "x_serg2_ems_am_cmdb_ci_monitoring_device"             = {}
      "x_serg2_ems_am_u_cmdb_ci_non_fitted_biometric_device" = {}
      "x_serg2_ems_csm_al_device_maintenance"                = {}
      "x_serg2_ems_csm_al_indication_fault"                  = {}
      "x_serg2_ems_csm_al_indication_noncompliance"          = {}
      "x_serg2_ems_csm_al_investigation_violation"           = {}
      "x_serg2_ems_csm_al_investigation_special"             = {}
      "x_serg2_ems_csm_al_notification_alert"                = {}
      "x_serg2_ems_csm_auto"                                 = {}
      "x_serg2_ems_csm_case"                                 = {}
      "x_serg2_ems_csm_complaints"                           = {}
      "x_serg2_ems_csm_compliments"                          = {}
      "x_serg2_ems_csm_enforcement_action"                   = {}
      "x_serg2_ems_csm_not_monitored"                        = {}
      "x_serg2_ems_csm_profile_device_wearer"                = {}
      "x_serg2_ems_csm_profile_sensitive"                    = {}
      "x_serg2_ems_csm_sr"                                   = {}
      "x_serg2_ems_csm_sr_info"                              = {}
      "x_serg2_ems_csm_sr_mo_existing"                       = {}
      "x_serg2_ems_csm_trials"                               = {}
      "x_serg2_ems_mom_commited_offence"                     = {}
      "x_serg2_ems_mom_mo"                                   = {}
      "x_serg2_ems_mom_monitoring_configuration"             = {}
      "x_serg2_ems_mom_mr"                                   = {}
      "x_serg2_ems_mom_violation"                            = {}
      "x_serg2_ems_mom_violation_mitigation"                 = {}
      "x_serg2_mdss_em_event_type"                           = {}
      "x_serg2_mdss_em_mdss_alert"                           = {}
    }
    "staging_fms" = {
      "stg_alm_asset_fms"                                            = {}
      "stg_asmt_assessment_instance_fms"                             = {}
      "stg_asmt_assessment_instance_question_fms"                    = {}
      "stg_alm_hardware_fms"                                         = {}
      "stg_alm_stockroom_fms"                                        = {}
      "stg_alm_transfer_order_fms"                                   = {}
      "stg_asmt_metric_fms"                                          = {}
      "stg_asmt_metric_result_fms"                                   = {}
      "stg_cmdb_hardware_product_model_fms"                          = {}
      "stg_cmn_location_fms"                                         = {}
      "stg_cmn_schedule_fms"                                         = {}
      "stg_cmn_schedule_span_fms"                                    = {}
      "stg_cmn_skill_level_fms"                                      = {}
      "stg_csm_consumer_fms"                                         = {}
      "stg_customer_account_fms"                                     = {}
      "stg_customer_contact_fms"                                     = {}
      "stg_interaction_fms"                                          = {}
      "stg_m2m_kb_task_fms"                                          = {}
      "stg_problem_fms"                                              = {}
      "stg_sm_asset_usage_fms"                                       = {}
      "stg_sm_part_requirement_fms"                                  = {}
      "stg_sn_customerservice_task_fms"                              = {}
      "stg_sys_choice_fms" = {}
      "stg_sys_dictionary_fms"                                       = {}
      "stg_sys_db_object_fms"                                        = {}
      "stg_wm_crew_fms"                                              = {}
      "stg_wm_crew_member_fms"                                       = {}
      "stg_wm_crew_skill_fms"                                        = {}
      "stg_wm_order_fms"                                             = {}
      "stg_wm_questionnaire_fms"                                     = {}
      "stg_wm_task_fms"                                              = {}
      "stg_wm_work_type_fms"                                         = {}
      "stg_x_serg2_ems_am_cmdb_ci_alcohol_monitoring_device_fms"     = {}
      "stg_x_serg2_ems_am_cmdb_ci_home_monitoring_unit_fms"          = {}
      "stg_x_serg2_ems_am_cmdb_ci_gps_monitoring_device_fms"         = {}
      "stg_x_serg2_ems_am_cmdb_ci_monitoring_device_fms"             = {}
      "stg_x_serg2_ems_am_u_cmdb_ci_non_fitted_biometric_device_fms" = {}
      "stg_x_serg2_ems_csm_al_device_maintenance_fms"                = {}
      "stg_x_serg2_ems_csm_al_indication_fault_fms"                  = {}
      "stg_x_serg2_ems_csm_al_indication_noncompliance_fms"          = {}
      "stg_x_serg2_ems_csm_al_investigation_violation_fms"           = {}
      "stg_x_serg2_ems_csm_al_investigation_special_fms"             = {}
      "stg_x_serg2_ems_csm_al_notification_alert_fms"                = {}
      "stg_x_serg2_ems_csm_auto_fms"                                 = {}
      "stg_x_serg2_ems_csm_case_fms"                                 = {}
      "stg_x_serg2_ems_csm_complaints_fms"                           = {}
      "stg_x_serg2_ems_csm_compliments_fms"                          = {}
      "stg_x_serg2_ems_csm_enforcement_action_fms"                   = {}
      "stg_x_serg2_ems_csm_not_monitored_fms"                        = {}
      "stg_x_serg2_ems_csm_profile_device_wearer_fms"                = {}
      "stg_x_serg2_ems_csm_profile_sensitive_fms"                    = {}
      "stg_x_serg2_ems_csm_sr_fms"                                   = {}
      "stg_x_serg2_ems_csm_sr_info_fms"                              = {}
      "stg_x_serg2_ems_csm_sr_mo_existing_fms"                       = {}
      "stg_x_serg2_ems_csm_trials_fms"                               = {}
      "stg_x_serg2_ems_mom_commited_offence_fms"                     = {}
      "stg_x_serg2_ems_mom_mo_fms"                                   = {}
      "stg_x_serg2_ems_mom_monitoring_configuration_fms"             = {}
      "stg_x_serg2_ems_mom_mr_fms"                                   = {}
      "stg_x_serg2_ems_mom_violation_fms"                            = {}
      "stg_x_serg2_ems_mom_violation_mitigation_fms"                 = {}
      "stg_x_serg2_mdss_em_event_type_fms"                           = {}
      "stg_x_serg2_mdss_em_mdss_alert_fms"                           = {}
    }
    "staging_mdss" = {
      "stg_curfew_rule_type_flag_mdss" = {}
      "stg_curfew_rule_type_mdss" = {}
      "stg_device_status_mdss" = {}
      "stg_event_status_mdss" = {}
      "stg_person_status_mdss" = {}
      "stg_person_type_mdss" = {}
      "stg_position_lbs_mdss" = {}
      "stg_sim_card_status_mdss" = {}
    }
    "intermediate_fms" = {
      "cemo_case_id_lookup" = {}
      "cemo_order_curfews_current" = {}
      "dd_device_wearer_current" = {}
      "dd_order_current" = {}
      "dd_violation_event_current" = {}
      "dd_work_order_fmo_visit_details_current" = {}
      "indications_of_noncompliance" = {}
      "indications_of_violations" = {}
    }
    "intermediate_mdss" = {
      "int_person_latest_event_report" = {}
      "int_person_latest_position_report" = {}
      "int_person_reports_in_event" = {}
      "int_person_reports_in_position" = {}
      "int_person_status_from_event" = {}
      "int_person_status_from_position" = {}
      "int_person_status_history_from_event" = {}
      "int_person_status_history_from_position" = {}
    }
    "datamart" = {
      "atv_fct" = {}
      "breaches_fct" = {}
      "date_dim" = {}
      "device_dim" = {}
      "device_wearer_dim" = {}
      "fmo_visit_fct" = {}
      "last_check_in_fct" = {}
      "order_dim" = {}
      "time_dim" = {}
      "violation_event_fct" = {}
    }
    "derived" = {
      "atv" = {}
      "breaches" = {}
      "daily_caseload" = {}
      "daily_caseload_count" = {}
      "monitoring_summary" = {}
      "not_monitored" = {}
      "visits" = {}
    }
    "acquisitive_crime" = {
      "caseload" = {}
      "daily_caseload_count" = {}
      "device_activations" = {}
      "position" = {}
    }
    "analysis"= {
      "breaches" = {}
      "daily_caseload" = {}
      "not_monitored" = {}
    }
    "data_insights" = {
      "caseload" = {}
      "curfew_atv" = {}
      "daily_caseload_count" = {}
      "device_activations" = {}
      "device_wearer_violations" = {}
      "position" = {}
    }
  }

  # Flatten tables into a single map keyed by "database.table" with merged config.
  tables_to_optimize_flat = merge([
    for database_name in local.database_to_optimize : {
      for table_name, config in local.tables_to_optimize[database_name] : "${database_name}.${table_name}" => merge(
        local.table_optimizer_defaults,
        config
      )
    }
  ]...)
}

resource "aws_glue_catalog_table_optimizer" "standard_compaction" {
  for_each      = local.tables_to_optimize_flat
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = split(".", each.key)[0] == "allied_mdss" || split(".", each.key)[0] == "serco_fms" ? "${split(".", each.key)[0]}${local.db_suffix}" : "${split(".", each.key)[0]}${local.dbt_suffix}"
  table_name    = split(".", each.key)[1]

  configuration {
    role_arn = aws_iam_role.glue_table_optimizer.arn
    enabled  = true
  }

  type = "compaction"
}

resource "aws_glue_catalog_table_optimizer" "standard_retention" {
  for_each      = local.tables_to_optimize_flat
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = "${split(".", each.key)[0]}${local.db_suffix}"
  table_name    = split(".", each.key)[1]

  configuration {
    role_arn = aws_iam_role.glue_table_optimizer.arn
    enabled  = true

    retention_configuration {
      iceberg_configuration {
        snapshot_retention_period_in_days = each.value.snapshot_retention_period_in_days
        number_of_snapshots_to_retain     = each.value.number_of_snapshots_to_retain
        clean_expired_files               = true
        run_rate_in_hours                 = each.value.retention_run_rate_in_hours
      }
    }
  }

  type = "retention"
}


resource "aws_glue_catalog_table_optimizer" "standard_orphan_file_deletion" {
  for_each      = local.tables_to_optimize_flat
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = "${split(".", each.key)[0]}${local.db_suffix}"
  table_name    = split(".", each.key)[1]

  configuration {
    role_arn = aws_iam_role.glue_table_optimizer.arn
    enabled  = true

    orphan_file_deletion_configuration {
      iceberg_configuration {
        orphan_file_retention_period_in_days = each.value.orphan_file_retention_period_in_days
        run_rate_in_hours                    = each.value.orphan_file_deletion_run_rate_in_hours
        location                             = "s3://${module.s3-create-a-derived-table-bucket.bucket.id}/staging/${split(".", each.key)[0]}${local.db_suffix}_pipeline/${split(".", each.key)[0]}${local.db_suffix}/${split(".", each.key)[1]}/"
      }
    }

  }

  type = "orphan_file_deletion"
}

data "aws_iam_policy_document" "glue_table_optimizer_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_table_optimizer" {
  name               = "glue-table-optimizer-role"
  assume_role_policy = data.aws_iam_policy_document.glue_table_optimizer_assume_role_policy.json
}

data "aws_iam_policy_document" "glue_table_optimizer_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:UpdateTable",
      "glue:GetTable",
      "glue:CreateTableOptimizer",
      "glue:GetTableOptimizer",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/iceberg-compaction/logs:*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/iceberg-retention/logs:*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/iceberg-orphan-file-deletion/logs:*"
    ]
  }
}

resource "aws_iam_policy" "glue_table_optimizer_policy" {
  name   = "glue-table-optimizer-policy"
  policy = data.aws_iam_policy_document.glue_table_optimizer_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_table_optimizer_policy_attachment" {
  role       = aws_iam_role.glue_table_optimizer.name
  policy_arn = aws_iam_policy.glue_table_optimizer_policy.arn
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_permissions" {
  principal   = aws_iam_role.glue_table_optimizer.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "glue_table_optimizer_table_permissions" {
  for_each    = toset(local.database_to_optimize)
  principal   = aws_iam_role.glue_table_optimizer.arn
  permissions = ["ALTER", "DESCRIBE", "INSERT", "DELETE"]
  table {
    database_name = "${each.key}${local.db_suffix}"
    wildcard      = true
  }
}


resource "aws_lakeformation_permissions" "glue_table_optimizer_database_permissions" {
  for_each    = toset(local.database_to_optimize)
  principal   = aws_iam_role.glue_table_optimizer.arn
  permissions = ["DESCRIBE"]
  database {
    name = "${each.key}${local.db_suffix}"
  }
}

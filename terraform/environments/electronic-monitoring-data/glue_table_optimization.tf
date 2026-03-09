locals {
    database_to_optimize = local.live_feeds_dbs
    tables_to_optimize   = {
        "allied_mdss": [
            "curfew",
            "curfew__rule",
            "curfew__zone",
            "device",
            "device_activation",
            "event",
            "person",
            "position",
        ],
        "serco_fms": [
            "alm_asset",
            "asmt_assessment_instance",
            "asmt_assessment_instance_question",
            "alm_hardware",
            "alm_stockroom",
            "alm_transfer_order",
            "asmt_metric",
            "asmt_metric_result",
            "cmdb_hardware_product_model",
            "cmn_location",
            "cmn_schedule",
            "cmn_schedule_span",
            "cmn_skill_level",
            "csm_consumer",
            "customer_account",
            "customer_contact",
            "interaction",
            "m2m_kb_task",
            "problem",
            "sm_asset_usage",
            "sm_part_requirement",
            "sn_customerservice_task",
            "sys_dictionary",
            "sys_db_object",
            "wm_crew",
            "wm_crew_member",
            "wm_crew_skill",
            "wm_order",
            "wm_questionnaire",
            "wm_task",
            "wm_work_type",
            "x_serg2_ems_am_cmdb_ci_alcohol_monitoring_device",
            "x_serg2_ems_am_cmdb_ci_home_monitoring_unit",
            "x_serg2_ems_am_cmdb_ci_gps_monitoring_device",
            "x_serg2_ems_am_cmdb_ci_monitoring_device",
            "x_serg2_ems_am_u_cmdb_ci_non_fitted_biometric_device",
            "x_serg2_ems_csm_al_device_maintenance",
            "x_serg2_ems_csm_al_indication_fault",
            "x_serg2_ems_csm_al_indication_noncompliance",
            "x_serg2_ems_csm_al_investigation_violation",
            "x_serg2_ems_csm_al_investigation_special",
            "x_serg2_ems_csm_al_notification_alert",
            "x_serg2_ems_csm_auto",
            "x_serg2_ems_csm_case",
            "x_serg2_ems_csm_complaints",
            "x_serg2_ems_csm_compliments",
            "x_serg2_ems_csm_enforcement_action",
            "x_serg2_ems_csm_not_monitored",
            "x_serg2_ems_csm_profile_device_wearer",
            "x_serg2_ems_csm_profile_sensitive",
            "x_serg2_ems_csm_sr",
            "x_serg2_ems_csm_sr_info",
            "x_serg2_ems_csm_sr_mo_existing",
            "x_serg2_ems_csm_trials",
            "x_serg2_ems_mom_commited_offence",
            "x_serg2_ems_mom_mo",
            "x_serg2_ems_mom_monitoring_configuration",
            "x_serg2_ems_mom_mr",
            "x_serg2_ems_mom_violation",
            "x_serg2_ems_mom_violation_mitigation",
            "x_serg2_mdss_em_event_type",
            "x_serg2_mdss_em_mdss_alert",
        ],
    }
}

resource "aws_glue_catalog_table_optimizer" "standard_compaction" {
    for_each = toset(flatten([
        for database_name in local.database_to_optimize : [
            for table_name in local.tables_to_optimize[database_name] : "${database_name}.${table_name}"
        ]
    ]))
    catalog_id    = data.aws_caller_identity.current.account_id
    database_name = split(".", each.key)[0]
    table_name    = split(".", each.key)[1]

    configuration {
        role_arn = aws_iam_role.glue_table_optimizer.arn
        enabled  = true
    }

    type = "compaction"
}

resource "aws_glue_catalog_table_optimizer" "standard_retention" {
    for_each = toset(flatten([
        for database_name in local.database_to_optimize : [
            for table_name in local.tables_to_optimize[database_name] : "${database_name}.${table_name}"
        ]
    ]))
    catalog_id    = data.aws_caller_identity.current.account_id
    database_name = split(".", each.key)[0]
    table_name    = split(".", each.key)[1]

  configuration {
    role_arn =  aws_iam_role.glue_table_optimizer.arn
    enabled  = true

    retention_configuration {
      iceberg_configuration {
        snapshot_retention_period_in_days = 7
        number_of_snapshots_to_retain     = 3
        clean_expired_files               = true
      }
    }
  }

  type = "retention"
}


resource "aws_glue_catalog_table_optimizer" "standard_orphan_file_deletion" {
    for_each = toset(flatten([
        for database_name in local.database_to_optimize : [
            for table_name in local.tables_to_optimize[database_name] : "${database_name}.${table_name}"
        ]
    ]))
  catalog_id    = data.aws_caller_identity.current.account_id
  database_name = split(".", each.key)[0]
  table_name    = split(".", each.key)[1]

  configuration {
    role_arn =  aws_iam_role.glue_table_optimizer.arn
    enabled  = true

    orphan_file_deletion_configuration {
      iceberg_configuration {
        orphan_file_retention_period_in_days = 7
        location                             = "s3://${module.s3-create-a-derived-table-bucket.bucket.id}/staging/${split(".", each.key)[0]}_pipeline/${split(".", each.key)[0]}/${split(".", each.key)[1]}/"
      }
    }

  }

  type = "orphan_file_deletion"
}

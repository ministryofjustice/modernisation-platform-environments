locals {
  deactivate_archive_trigger = {
    "StepName" : "Deactivate Archive Trigger",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_trigger_activation_job,
        "Arguments" : {
          "--dpr.glue.trigger.name" : var.archive_job_trigger_name,
          "--dpr.glue.trigger.activate" : "false"
        }
      },
      "Next" : local.stop_archive_job.StepName
    }
  }

  stop_archive_job = {
    "StepName" : "Stop Archive Job",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_stop_glue_instance_job,
        "Arguments" : {
          "--dpr.stop.glue.instance.job.name" : var.glue_archive_job
        }
      },
      "Next" : var.split_pipeline ? local.stop_dms_cdc_replication_task.StepName : local.stop_dms_replication_task.StepName
    }
  }

  stop_dms_replication_task = {
    "StepName" : "Stop DMS Replication Task",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.stop_dms_task_job,
        "Arguments" : {
          "--dpr.dms.replication.task.id" : var.replication_task_id
        }
      },
      "Next" : var.batch_only ? local.update_hive_tables.StepName : local.stop_glue_streaming_job.StepName
    }
  }

  stop_dms_cdc_replication_task = {
    "StepName" : "Stop DMS CDC Replication Task",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.stop_dms_task_job,
        "Arguments" : {
          "--dpr.dms.replication.task.id" : var.cdc_replication_task_id
        }
      },
      "Next" : local.stop_glue_streaming_job.StepName
    }
  }

  stop_glue_streaming_job = {
    "StepName" : "Stop Glue Streaming Job",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_stop_glue_instance_job,
        "Arguments" : {
          "--dpr.stop.glue.instance.job.name" : var.glue_reporting_hub_cdc_jobname
        }
      },
      "Next" : local.update_hive_tables.StepName
    }
  }

  update_hive_tables = {
    "StepName" : "Update Hive Tables",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_hive_table_creation_jobname,
        "Arguments" : {
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.prepare_temp_reload_bucket_data.StepName
    }
  }

  prepare_temp_reload_bucket_data = {
    "StepName" : "Prepare Temp Reload Bucket Data",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_s3_data_deletion_job,
        "Arguments" : {
          "--dpr.file.deletion.buckets" : var.s3_temp_reload_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.copy_curated_data_to_temp_reload_bucket.StepName
    }
  }

  copy_curated_data_to_temp_reload_bucket = {
    "StepName" : "Copy Curated Data to Temp-Reload Bucket",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_s3_file_transfer_job,
        "Arguments" : {
          "--dpr.file.transfer.source.bucket" : var.s3_curated_bucket_id,
          "--dpr.file.transfer.destination.bucket" : var.s3_temp_reload_bucket_id,
          "--dpr.file.transfer.retention.period.amount" : "0",
          "--dpr.file.transfer.delete.copied.files" : "false",
          "--dpr.datastorage.retry.maxAttempts" : tostring(var.glue_s3_max_attempts),
          "--dpr.datastorage.retry.minWaitMillis" : tostring(var.glue_s3_retry_min_wait_millis),
          "--dpr.datastorage.retry.maxWaitMillis" : tostring(var.glue_s3_retry_max_wait_millis),
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepName
    }
  }

  switch_hive_tables_for_prisons_to_temp_reload_bucket = {
    "StepName" : "Switch Hive Tables for Prisons to Temp-Reload Bucket",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_switch_prisons_hive_data_location_job,
        "Arguments" : {
          "--dpr.prisons.data.switch.target.s3.path" : "s3://${var.s3_temp_reload_bucket_id}",
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.empty_raw_archive_structured_and_curated_data.StepName
    }
  }

  empty_raw_archive_structured_and_curated_data = {
    "StepName" : "Empty Raw, Archive, Structured and Curated Data",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_s3_data_deletion_job,
        "Arguments" : {
          "--dpr.file.deletion.buckets" : "${var.s3_raw_bucket_id},${var.s3_raw_archive_bucket_id},${var.s3_structured_bucket_id},${var.s3_curated_bucket_id}",
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.start_dms_replication_task.StepName
    }
  }

  set_dms_cdc_replication_task_start_time = {
    "StepName" : "Set DMS CDC Replication Task Start Time",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.set_cdc_dms_start_time_job,
        "Arguments" : {
          "--dpr.dms.replication.task.id" : var.replication_task_id,
          "--dpr.cdc.dms.replication.task.id" : var.cdc_replication_task_id
        }
      },
      "Next" : local.run_glue_batch_job.StepName
    }
  }

  start_dms_replication_task = {
    "StepName" : "Start DMS Replication Task",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
      "Parameters" : {
        "ReplicationTaskArn" : var.dms_replication_task_arn,
        "StartReplicationTaskType" : "reload-target"
      },
      "Next" : local.invoke_dms_state_control_lambda.StepName
    }
  }

  invoke_dms_state_control_lambda = {
    "StepName" : "Invoke DMS State Control Lambda",
    "StepDefinition" : {
      "Type" : "Task",
      "TimeoutSeconds" : var.pipeline_dms_task_time_out,
      "Resource" : "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters" : {
        "Payload" : {
          "token.$" : "$$.Task.Token",
          "ignoreDmsTaskFailure" : var.pipeline_notification_lambda_function_ignore_dms_failure,
          "replicationTaskArn" : var.dms_replication_task_arn
        },
        "FunctionName" : var.pipeline_notification_lambda_function
      },
      "Retry" : [
        {
          "ErrorEquals" : [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds" : 60,
          "MaxAttempts" : 2,
          "BackoffRate" : 2
        }
      ],
      "Next" : var.split_pipeline ? local.set_dms_cdc_replication_task_start_time.StepName : local.run_glue_batch_job.StepName
    }
  }

  run_glue_batch_job = {
    "StepName" : "Run Glue Batch Job",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_reporting_hub_batch_jobname,
        "Arguments" : {
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.archive_raw_data.StepName
    }
  }

  archive_raw_data = {
    "StepName" : "Archive Raw Data",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_s3_file_transfer_job,
        "Arguments" : {
          "--dpr.file.transfer.source.bucket" : var.s3_raw_bucket_id,
          "--dpr.file.transfer.destination.bucket" : var.s3_raw_archive_bucket_id,
          "--dpr.file.transfer.retention.period.amount" : "0",
          "--dpr.file.transfer.delete.copied.files" : "true",
          "--dpr.datastorage.retry.maxAttempts" : tostring(var.glue_s3_max_attempts),
          "--dpr.datastorage.retry.minWaitMillis" : tostring(var.glue_s3_retry_min_wait_millis),
          "--dpr.datastorage.retry.maxWaitMillis" : tostring(var.glue_s3_retry_max_wait_millis),
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : var.split_pipeline ? local.start_dms_cdc_replication_task.StepName : local.run_compaction_job_on_structured_zone.StepName
    }
  }

  run_compaction_job_on_structured_zone = {
    "StepName" : "Run Compaction Job on Structured Zone",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_maintenance_compaction_job,
        "Arguments" : {
          "--dpr.maintenance.root.path" : var.s3_structured_path,
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        },
        "NumberOfWorkers" : var.compaction_structured_num_workers,
        "WorkerType" : var.compaction_structured_worker_type
      },
      "Next" : local.run_vacuum_job_on_structured_zone.StepName
    }
  }

  run_vacuum_job_on_structured_zone = {
    "StepName" : "Run Vacuum Job on Structured Zone",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_maintenance_retention_job,
        "Arguments" : {
          "--dpr.maintenance.root.path" : var.s3_structured_path,
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        },
        "NumberOfWorkers" : var.retention_structured_num_workers,
        "WorkerType" : var.retention_structured_worker_type
      },
      "Next" : local.run_compaction_job_on_curated_zone.StepName
    }
  }

  run_compaction_job_on_curated_zone = {
    "StepName" : "Run Compaction Job on Curated Zone",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_maintenance_compaction_job,
        "Arguments" : {
          "--dpr.maintenance.root.path" : var.s3_curated_path,
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        },
        "NumberOfWorkers" : var.compaction_curated_num_workers,
        "WorkerType" : var.compaction_curated_worker_type
      },
      "Next" : local.run_vacuum_job_on_curated_zone.StepName
    }
  }

  run_vacuum_job_on_curated_zone = {
    "StepName" : "Run Vacuum Job on Curated Zone",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_maintenance_retention_job,
        "Arguments" : {
          "--dpr.maintenance.root.path" : var.s3_curated_path,
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        },
        "NumberOfWorkers" : var.retention_curated_num_workers,
        "WorkerType" : var.retention_curated_worker_type
      },
      "Next" : var.batch_only ? local.run_reconciliation_job.StepName : local.resume_dms_replication_task.StepName
    }
  }

  start_dms_cdc_replication_task = {
    "StepName" : "Start DMS CDC Replication Task",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
      "Parameters" : {
        "ReplicationTaskArn" : var.dms_cdc_replication_task_arn,
        "StartReplicationTaskType" : "start-replication"
      },
      "Next" : local.start_glue_streaming_job.StepName
    }
  }

  resume_dms_replication_task = {
    "StepName" : "Resume DMS Replication Task",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::aws-sdk:databasemigration:startReplicationTask",
      "Parameters" : {
        "ReplicationTaskArn" : var.dms_replication_task_arn,
        "StartReplicationTaskType" : "resume-processing"
      },
      "Next" : local.start_glue_streaming_job.StepName
    }
  }

  start_glue_streaming_job = {
    "StepName" : "Start Glue Streaming Job",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun",
      "Parameters" : {
        "JobName" : var.glue_reporting_hub_cdc_jobname,
        "Arguments" : {
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : local.switch_hive_tables_for_prisons_to_curated.StepName
    }
  }

  run_reconciliation_job = {
    "StepName" : "Run Reconciliation Job",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_reconciliation_job,
        "Arguments" : {
          "--dpr.reconciliation.checks.to.run" : "current_state_counts",
          "--dpr.config.s3.bucket" : var.s3_glue_bucket_id,
          "--dpr.config.key" : var.domain
        },
        "NumberOfWorkers" : var.glue_reconciliation_job_num_workers,
        "WorkerType" : var.glue_reconciliation_job_worker_type
      },
      "Next" : local.switch_hive_tables_for_prisons_to_curated.StepName
    }
  }

  switch_hive_tables_for_prisons_to_curated = {
    "StepName" : "Switch Hive Tables for Prisons to Curated",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_switch_prisons_hive_data_location_job,
        "Arguments" : {
          "--dpr.prisons.data.switch.target.s3.path" : "s3://${var.s3_curated_bucket_id}",
          "--dpr.config.key" : var.domain
        }
      },
      "Next" : var.batch_only ? local.empty_temp_reload_bucket_data.StepName : local.reactivate_archive_trigger.StepName
    }
  }

  reactivate_archive_trigger = {
    "StepName" : "Reactivate Archive Trigger",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_trigger_activation_job,
        "Arguments" : {
          "--dpr.glue.trigger.name" : var.archive_job_trigger_name,
          "--dpr.glue.trigger.activate" : "true"
        }
      },
      "Next" : local.empty_temp_reload_bucket_data.StepName
    }
  }

  empty_temp_reload_bucket_data = {
    "StepName" : "Empty Temp Reload Bucket Data",
    "StepDefinition" : {
      "Type" : "Task",
      "Resource" : "arn:aws:states:::glue:startJobRun.sync",
      "Parameters" : {
        "JobName" : var.glue_s3_data_deletion_job,
        "Arguments" : {
          "--dpr.file.deletion.buckets" : var.s3_temp_reload_bucket_id,
          "--dpr.config.key" : var.domain
        }
      },
      "End" : true
    }
  }
}

# Data Ingest Pipeline Step Function
module "data_ingestion_pipeline" {
  source = "../../step_function"

  enable_step_function = var.setup_data_ingestion_pipeline
  step_function_name   = var.data_ingestion_pipeline
  dms_task_time_out    = var.pipeline_dms_task_time_out

  step_function_execution_role_arn = var.step_function_execution_role_arn

  definition = var.batch_only ? jsonencode(
    {
      "Comment" : "Data Ingestion Pipeline Step Function (Batch Only)",
      "StartAt" : local.stop_dms_replication_task.StepName,
      "States" : {
        (local.stop_dms_replication_task.StepName) : local.stop_dms_replication_task.StepDefinition,
        (local.update_hive_tables.StepName) : local.update_hive_tables.StepDefinition,
        (local.prepare_temp_reload_bucket_data.StepName) : local.prepare_temp_reload_bucket_data.StepDefinition,
        (local.copy_curated_data_to_temp_reload_bucket.StepName) : local.copy_curated_data_to_temp_reload_bucket.StepDefinition,
        (local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepName) : local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepDefinition,
        (local.empty_raw_archive_structured_and_curated_data.StepName) : local.empty_raw_archive_structured_and_curated_data.StepDefinition,
        (local.start_dms_replication_task.StepName) : local.start_dms_replication_task.StepDefinition,
        (local.invoke_dms_state_control_lambda.StepName) : local.invoke_dms_state_control_lambda.StepDefinition,
        (local.run_glue_batch_job.StepName) : local.run_glue_batch_job.StepDefinition,
        (local.archive_raw_data.StepName) : local.archive_raw_data.StepDefinition,
        (local.run_compaction_job_on_structured_zone.StepName) : local.run_compaction_job_on_structured_zone.StepDefinition,
        (local.run_vacuum_job_on_structured_zone.StepName) : local.run_vacuum_job_on_structured_zone.StepDefinition,
        (local.run_compaction_job_on_curated_zone.StepName) : local.run_compaction_job_on_curated_zone.StepDefinition,
        (local.run_vacuum_job_on_curated_zone.StepName) : local.run_vacuum_job_on_curated_zone.StepDefinition,
        (local.run_reconciliation_job.StepName) : local.run_reconciliation_job.StepDefinition,
        (local.switch_hive_tables_for_prisons_to_curated.StepName) : local.switch_hive_tables_for_prisons_to_curated.StepDefinition,
        (local.empty_temp_reload_bucket_data.StepName) : local.empty_temp_reload_bucket_data.StepDefinition
      }
    }
    ) : var.split_pipeline ? jsonencode(
    {
      "Comment" : "Data Ingestion Pipeline Step Function (With Separated Full-Load and CDC Tasks)",
      "StartAt" : local.deactivate_archive_trigger.StepName,
      "States" : {
        (local.deactivate_archive_trigger.StepName) : local.deactivate_archive_trigger.StepDefinition,
        (local.stop_archive_job.StepName) : local.stop_archive_job.StepDefinition,
        (local.stop_dms_cdc_replication_task.StepName) : local.stop_dms_cdc_replication_task.StepDefinition,
        (local.stop_glue_streaming_job.StepName) : local.stop_glue_streaming_job.StepDefinition,
        (local.update_hive_tables.StepName) : local.update_hive_tables.StepDefinition,
        (local.prepare_temp_reload_bucket_data.StepName) : local.prepare_temp_reload_bucket_data.StepDefinition,
        (local.copy_curated_data_to_temp_reload_bucket.StepName) : local.copy_curated_data_to_temp_reload_bucket.StepDefinition,
        (local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepName) : local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepDefinition,
        (local.empty_raw_archive_structured_and_curated_data.StepName) : local.empty_raw_archive_structured_and_curated_data.StepDefinition,
        (local.start_dms_replication_task.StepName) : local.start_dms_replication_task.StepDefinition,
        (local.invoke_dms_state_control_lambda.StepName) : local.invoke_dms_state_control_lambda.StepDefinition,
        (local.set_dms_cdc_replication_task_start_time.StepName) : local.set_dms_cdc_replication_task_start_time.StepDefinition,
        (local.run_glue_batch_job.StepName) : local.run_glue_batch_job.StepDefinition,
        (local.archive_raw_data.StepName) : local.archive_raw_data.StepDefinition,
        (local.start_dms_cdc_replication_task.StepName) : local.start_dms_cdc_replication_task.StepDefinition,
        (local.start_glue_streaming_job.StepName) : local.start_glue_streaming_job.StepDefinition,
        (local.switch_hive_tables_for_prisons_to_curated.StepName) : local.switch_hive_tables_for_prisons_to_curated.StepDefinition,
        (local.reactivate_archive_trigger.StepName) : local.reactivate_archive_trigger.StepDefinition,
        (local.empty_temp_reload_bucket_data.StepName) : local.empty_temp_reload_bucket_data.StepDefinition,
      }
    }
    ) : jsonencode(
    {
      "Comment" : "Data Ingestion Pipeline Step Function",
      "StartAt" : local.deactivate_archive_trigger.StepName,
      "States" : {
        (local.deactivate_archive_trigger.StepName) : local.deactivate_archive_trigger.StepDefinition,
        (local.stop_archive_job.StepName) : local.stop_archive_job.StepDefinition,
        (local.stop_dms_replication_task.StepName) : local.stop_dms_replication_task.StepDefinition,
        (local.stop_glue_streaming_job.StepName) : local.stop_glue_streaming_job.StepDefinition,
        (local.update_hive_tables.StepName) : local.update_hive_tables.StepDefinition,
        (local.prepare_temp_reload_bucket_data.StepName) : local.prepare_temp_reload_bucket_data.StepDefinition,
        (local.copy_curated_data_to_temp_reload_bucket.StepName) : local.copy_curated_data_to_temp_reload_bucket.StepDefinition,
        (local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepName) : local.switch_hive_tables_for_prisons_to_temp_reload_bucket.StepDefinition,
        (local.empty_raw_archive_structured_and_curated_data.StepName) : local.empty_raw_archive_structured_and_curated_data.StepDefinition,
        (local.start_dms_replication_task.StepName) : local.start_dms_replication_task.StepDefinition,
        (local.invoke_dms_state_control_lambda.StepName) : local.invoke_dms_state_control_lambda.StepDefinition,
        (local.run_glue_batch_job.StepName) : local.run_glue_batch_job.StepDefinition,
        (local.archive_raw_data.StepName) : local.archive_raw_data.StepDefinition,
        (local.run_compaction_job_on_structured_zone.StepName) : local.run_compaction_job_on_structured_zone.StepDefinition,
        (local.run_vacuum_job_on_structured_zone.StepName) : local.run_vacuum_job_on_structured_zone.StepDefinition,
        (local.run_compaction_job_on_curated_zone.StepName) : local.run_compaction_job_on_curated_zone.StepDefinition,
        (local.run_vacuum_job_on_curated_zone.StepName) : local.run_vacuum_job_on_curated_zone.StepDefinition,
        (local.resume_dms_replication_task.StepName) : local.resume_dms_replication_task.StepDefinition,
        (local.start_glue_streaming_job.StepName) : local.start_glue_streaming_job.StepDefinition,
        (local.switch_hive_tables_for_prisons_to_curated.StepName) : local.switch_hive_tables_for_prisons_to_curated.StepDefinition,
        (local.reactivate_archive_trigger.StepName) : local.reactivate_archive_trigger.StepDefinition,
        (local.empty_temp_reload_bucket_data.StepName) : local.empty_temp_reload_bucket_data.StepDefinition,
      }
    }
  )

  tags = var.tags

}
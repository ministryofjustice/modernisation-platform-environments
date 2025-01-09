# Step Function for Stopping the CDC Pipeline
module "cdc_stop_pipeline" {
  source = "../../step_function"

  enable_step_function = var.setup_stop_cdc_pipeline
  step_function_name   = var.stop_cdc_pipeline

  step_function_execution_role_arn = var.step_function_execution_role_arn

  definition = jsonencode(
    {
      "Comment" : "Step Function for Stopping the CDC Pipeline",
      "StartAt" : "Stop DMS Replication Task",
      "States" : {
        "Stop DMS Replication Task" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.stop_dms_task_job,
            "Arguments" : {
              "--dpr.dms.replication.task.id" : var.replication_task_id
            }
          },
          "Next" : "Check All Pending Files Have Been Processed"
        },
        "Check All Pending Files Have Been Processed" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_unprocessed_raw_files_check_job,
            "Arguments" : {
              "--dpr.orchestration.wait.interval.seconds" : tostring(var.processed_files_check_wait_interval_seconds),
              "--dpr.orchestration.max.attempts" : tostring(var.processed_files_check_max_attempts)
            }
          },
          "Next" : "Stop Glue Streaming Job"
        },
        "Stop Glue Streaming Job" : {
          "Type" : "Task",
          "Resource" : "arn:aws:states:::glue:startJobRun.sync",
          "Parameters" : {
            "JobName" : var.glue_stop_glue_instance_job,
            "Arguments" : {
              "--dpr.stop.glue.instance.job.name" : var.glue_reporting_hub_cdc_jobname
            }
          },
          "End" : true
        }
      }
    }
  )

  tags = var.tags

}
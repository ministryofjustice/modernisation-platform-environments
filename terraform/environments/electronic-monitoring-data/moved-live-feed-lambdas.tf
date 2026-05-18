#delete this file after TF has been applied to all 4 envs
moved {
  from = module.format_json_fms_data
  to   = module.fms_raw_file_formatter
}

moved {
  from = module.copy_mdss_data
  to   = module.mdss_raw_file_stager
}

moved {
  from = module.process_fms_metadata
  to   = module.fms_expected_file_processor
}

moved {
  from = module.mdss_daily_failure_digest
  to   = module.live_feed_daily_handover
}

moved {
  from = module.fan_out_tags
  to   = module.fms_validation_rejection_fanout
}

moved {
  from = module.mdss_reconciler[0]
  to   = module.mdss_load_redrive_controller[0]
}

moved {
  from = module.landing_dlq_redriver
  to   = module.landing_file_dlq_redriver
}
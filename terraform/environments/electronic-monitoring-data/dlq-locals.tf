locals {
  live_feed_dlq_names = {
    process_landing_bucket_files_fms_general  = "-process_landing_bucket_files_fms_general-dlq"
    process_landing_bucket_files_fms_ho       = "-process_landing_bucket_files_fms_ho-dlq"
    process_landing_bucket_files_fms_specials = "-process_landing_bucket_files_fms_specials-dlq"

    process_landing_bucket_files_mdss_general  = "-process_landing_bucket_files_mdss_general-dlq"
    process_landing_bucket_files_mdss_ho       = "-process_landing_bucket_files_mdss_ho-dlq"
    process_landing_bucket_files_mdss_specials = "-process_landing_bucket_files_mdss_specials-dlq"

    scan                   = "-scan-dlq"
    process_fms_metadata   = "-process_fms_metadata-dlq"
    push_data_export_to_p1 = "-push_data_export_to_p1-dlq"
  }
}
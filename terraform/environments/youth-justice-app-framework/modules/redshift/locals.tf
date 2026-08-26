locals {
  namespace_name = "${var.project_name}-${var.environment}-yjbservices"

  yjb_bucket_name = "redshift-yjb-reporting"
  ycs_bucket_name = "redshift-ycs-reporting"

  yjb_bucket_id = "${var.project_name}-${var.environment}-${local.yjb_bucket_name}"

  yjb_s3_folder_moj_ap  = "moj_ap"
  yjb_s3_folder_landing = "landing"

}
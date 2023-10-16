

resource "aws_dms_s3_endpoint" "dms-s3-target" {
  endpoint_id             = "${var.project_id}-dms-${var.short_name}-s3-target"
  endpoint_type           = "target"
  bucket_name             = var.bucket_name
  service_access_role_arn = aws_iam_role.dms-s3-role.arn
  data_format             = "parquet"
  cdc_path = "cdc"

  cdc_max_batch_interval = 10
  include_op_for_full_load = true
  cdc_inserts_and_updates = true

  depends_on = [aws_iam_role_policy.dms-s3-target-policy]

  tags = {
    Resource_Type = "DMS Target"
    Jira          = "DPR2-165"
  }
}
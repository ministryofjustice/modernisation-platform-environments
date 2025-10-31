locals {
  # Only enable instance trmination protection if not in test mode
  disable_api_termination = var.test_mode ? false : true
  # Enable deletion of storage with the instance in test mode only.
  delete_on_termination = var.test_mode
  # Only enable ALB deletion protection if not in test mode
  enable_deletion_protection = var.test_mode ? false : true

  instance_key_name = "${var.project_name}-${var.environment}-${var.instance_key_name}"

  alb_access_logs_bucket_name_suffix = "tableau-alb-logs"

  tableau-backups-bucket-name = "tableau-backups"
}
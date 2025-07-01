module "transfer_structured_logs" {
  source = "./modules/cloudwatch_logs"  # Or a registry path
  log_group_name = "/aws/transfer/${local.environment}-sftp"
}

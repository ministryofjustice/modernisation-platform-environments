locals {
  file_transfer_workflow_maximum_size_bytes = 5000000000000
  file_transfer_workflow_part_size_bytes    = 5000000000
  file_transfer_workflow_timeout_seconds    = 86400
  file_transfer_workflow_lease_seconds      = local.file_transfer_workflow_timeout_seconds + 3600
}
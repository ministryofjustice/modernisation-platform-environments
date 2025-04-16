resource "aws_ecr_repository" "file_transfer_in_clamav_scanner" {
  name                 = "${local.project}-images-${local.env}/hmpps-data-hub-clamav-s3-scanner"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-hive-table-creation-${local.env}"
      Resource_Type = "ECR repository"
      Jira          = "DPR2-1499"
    }
  )
}
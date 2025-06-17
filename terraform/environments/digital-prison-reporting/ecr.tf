# Used to store our custom clamav S3 scanner image for File Transfer In/Push
resource "aws_ecr_repository" "file_transfer_in_clamav_scanner" {
  #checkov:skip=CKV_AWS_51:Ensure ECR Image Tags are immutable - we explicitly want to use a mutable latest tag to manage versions in the image repo
  name                 = "${local.project}-container-images/hmpps-dpr-landing-zone-antivirus-check"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
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
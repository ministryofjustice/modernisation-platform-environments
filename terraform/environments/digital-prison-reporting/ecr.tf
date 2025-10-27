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
      name          = "${local.project}-container-images/hmpps-dpr-landing-zone-antivirus-check"
      resource-type = "ECR repository"
      jira          = "DPR2-1499"
    }
  )
}

resource "aws_ecr_repository_policy" "file_transfer_in_clamav_scanner_policy" {
  repository = aws_ecr_repository.file_transfer_in_clamav_scanner.name

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "LambdaECRImageRetrievalPolicy"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com"]
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:DeleteRepositoryPolicy",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:SetRepositoryPolicy"
        ]
        Condition = {
          StringLike = {
            "aws:sourceArn" = "arn:aws:lambda:${local.account_region}:${local.account_id}:function:*"
          }
        }
      }
    ]
  })
}

#-----------------------------------------------------------------------------------
# Virus scanning - definition upload
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "virus_scan_definition_upload" {
  name               = "virus_scan_definition_upload"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "virus_scan_definition_upload_policy_document" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.s3-clamav-definitions-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "virus_scan_definition_upload" {
  name        = "virus-scan-definitions-upload-policy"
  description = "Policy for Lambda to get and upload latest clamav virus definitions"
  policy      = data.aws_iam_policy_document.virus_scan_definition_upload_policy_document.json
}

resource "aws_iam_role_policy_attachment" "virus_scan_definition_upload_policy_attachment" {
  role       = aws_iam_role.virus_scan_definition_upload.name
  policy_arn = aws_iam_policy.virus_scan_definition_upload.arn
}

#-----------------------------------------------------------------------------------
# Virus scanning - file scanning
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "virus_scan_file" {
  name               = "virus_scan_file"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "virus_scan_file_policy_document" {
  statement {
    sid    = "S3PermissionsForScanDefinitionsBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${module.s3-clamav-definitions-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3PermissionsForReceivedBucket"
    effect = "Allow"
    actions = [
      "s3:CopyObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]
    resources = ["${module.s3-received-files-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3PermissionsForQuarantineAndProcessedBucket"
    effect = "Allow"
    actions = [
      "s3:CopyObject",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${module.s3-quarantine-files-bucket.bucket.arn}/*",
      "${module.s3-data-bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "virus_scan_file" {
  name        = "virus-scan-file-policy"
  description = "Policy for Lambda to virus scan and move files"
  policy      = data.aws_iam_policy_document.virus_scan_file_policy_document.json
}

resource "aws_iam_role_policy_attachment" "virus_scan_file_policy_attachment" {
  role       = aws_iam_role.virus_scan_file.name
  policy_arn = aws_iam_policy.virus_scan_file.arn
}

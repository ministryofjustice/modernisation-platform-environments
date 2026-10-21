data "aws_iam_policy_document" "api_incoming_upload" {
  count = local.api_upload_enabled ? 1 : 0

  statement {
    sid       = "AllowApiUploads"
    actions   = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts"]
    resources = local.api_upload_resources
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.api_account_id}:root"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [local.api_upload_role_arn]
    }
  }
}

locals {
  api_account_id      = local.environment_management.account_ids["integration-hub-api-${local.environment}"]
  api_upload_role_arn = "arn:aws:iam::${local.api_account_id}:role/integration-hub-api-platform-upload-ticket"
  # Match the server-managed API client configuration; never accept caller prefixes.
  api_clients = try(jsondecode(file("${path.module}/../integration-hub-api/modules/file-transfer-api/application_variables.json")).accounts[local.environment].transfer_clients, {})
  api_upload_resources = [
    for client in values(local.api_clients) : "arn:aws:s3:::${local.application_name}-${local.environment}-incoming/${trim(client.key_prefix, "/")}/*"
    if try(client.enabled, true)
  ]
  api_deployment_role_arns = [
    for role in ["github-actions-plan", "github-actions-apply", "MemberInfrastructureAccess", var.collaborator_access] :
    "arn:aws:iam::${local.api_account_id}:role/${role}"
  ]
  # Exact role conditions let MFT deploy before the API execution role exists.
  api_incoming_key_statements = [
    {
      sid       = "AllowApiUploadEncryption"
      actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
      resources = ["*"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.api_account_id}:root"]
      }]
      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:PrincipalArn"
          values   = [local.api_upload_role_arn]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["s3.eu-west-2.amazonaws.com"]
        },
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:s3:arn"
          values   = local.api_upload_resources
        }
      ]
    },
    {
      sid       = "AllowApiDeploymentKeyDiscovery"
      actions   = ["kms:DescribeKey"]
      resources = ["*"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.api_account_id}:root"]
      }]
      condition = [{
        test     = "ArnEquals"
        variable = "aws:PrincipalArn"
        values   = local.api_deployment_role_arns
      }]
    }
  ]
}

data "aws_iam_policy_document" "api_incoming_upload" {
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

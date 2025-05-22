resource "aws_secretsmanager_secret" "ip_block_list" {
# checkov:skip=CKV2_AWS_57:Auto rotation not possible
  name        = "ip_block_list"
  description = "Secret for storing IP block list"
  kms_key_id = data.aws_kms_key.general_shared.arn
  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "ip_block_list_version" {
  secret_id     = aws_secretsmanager_secret.ip_block_list.id
  secret_string = "{}"  # Initialize as empty, populate later
  
}

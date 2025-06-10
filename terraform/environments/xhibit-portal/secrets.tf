resource "aws_secretsmanager_secret" "ip_block_list" {
  # checkov:skip=CKV2_AWS_57:Auto rotation not possible
  # checkov:skip=CKV_AWS_149: Default encryption is fine
  name        = "ip_block_list"
  description = "Secret for storing IP block list"
  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "ip_block_list_version" {
  secret_id     = aws_secretsmanager_secret.ip_block_list.id
  secret_string = "{}" # Initialize as empty, populate later

}
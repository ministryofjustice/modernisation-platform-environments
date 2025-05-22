resource "aws_secretsmanager_secret" "ip_block_list" {
  name        = "ip_block_list"
  description = "Secret for storing IP block list"
  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "ip_block_list_version" {
  secret_id     = aws_secretsmanager_secret.ip_block_list.id
  secret_string = "{}"  # Initialize as empty, populate later
  tags = merge(
    local.tags
  )
}

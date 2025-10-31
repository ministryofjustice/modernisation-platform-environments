resource "aws_transfer_ssh_key" "this" {
  server_id = var.server_id
  user_name = var.user_name
  body      = var.ssh_key_body
}

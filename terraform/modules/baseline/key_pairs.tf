resource "aws_key_pair" "this" {
  for_each = var.key_pairs

  key_name   = each.key
  public_key = each.value.public_key_filename != null ? file(each.value.public_key_filename) : each.value.public_key

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

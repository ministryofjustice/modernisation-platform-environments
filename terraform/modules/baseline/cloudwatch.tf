resource "aws_cloudwatch_log_group" "this" {
  for_each = var.cloudwatch_log_groups

  name              = each.key
  retention_in_days = each.value.retention_in_days
  skip_destroy      = each.value.skip_destroy
  kms_key_id        = each.value.kms_key_id

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

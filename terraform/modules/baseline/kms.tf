resource "aws_kms_grant" "this" {
  # for_each keys only to avoid sensitive value for_each error
  for_each = nonsensitive(toset(keys(var.kms_grants)))

  name              = each.key
  key_id            = var.kms_grants[each.key].key_id
  grantee_principal = var.kms_grants[each.key].grantee_principal
  operations        = var.kms_grants[each.key].operations

  # ensure principals are created first
  depends_on = [
    aws_iam_role.this,
    aws_iam_service_linked_role.this
  ]
}

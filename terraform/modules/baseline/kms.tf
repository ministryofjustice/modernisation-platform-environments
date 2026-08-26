resource "aws_kms_grant" "this" {
  for_each = var.kms_grants

  name              = each.key
  key_id            = each.value.key_id
  grantee_principal = each.value.grantee_principal
  operations        = each.value.operations

  # ensure principals are created first
  depends_on = [
    aws_iam_role.this,
    aws_iam_service_linked_role.this
  ]
}

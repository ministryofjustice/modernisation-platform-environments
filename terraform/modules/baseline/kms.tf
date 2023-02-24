resource "aws_kms_grant" "this" {
  for_each = var.kms_grants

  name              = each.key
  key_id            = each.value.key_id
  grantee_principal = each.value.grantee_principal
  operations        = each.value.operations
}

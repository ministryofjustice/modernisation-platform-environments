resource "aws_kms_grant" "this" {
  # There's a weird issue where args can flip between sensitive and non-sensitive
  # value seen in nomis-data-hub accounts only.  Hence the nonsensitive workaround
  # here.  Looks like a bug so try removing at some point in future.
  for_each = nonsensitive(sensitive(toset(keys(var.kms_grants))))

  name              = each.key
  key_id            = nonsensitive(sensitive(var.kms_grants[each.key].key_id))
  grantee_principal = var.kms_grants[each.key].grantee_principal
  operations        = nonsensitive(sensitive(var.kms_grants[each.key].operations))

  # ensure principals are created first
  depends_on = [
    aws_iam_role.this,
    aws_iam_service_linked_role.this
  ]
}

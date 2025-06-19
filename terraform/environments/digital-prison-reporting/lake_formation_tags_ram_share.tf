# RAM share for LF tags to APDP (only if lf_tags are defined)
resource "aws_ram_resource_share" "lf_tag_share_apdp" {
  count = local.lf_tags != null && length(local.lf_tags) > 0 ? 1 : 0

  name                      = "lf-tag-share-to-apdp"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "lf_tag_share_apdp_principal" {
  count = local.lf_tags != null && length(local.lf_tags) > 0 ? 1 : 0

  principal          = "593291632749"  # APDP account ID
  resource_share_arn = aws_ram_resource_share.lf_tag_share_apdp[0].arn
}

resource "aws_ram_resource_association" "share_lf_tags" {
  for_each = local.lf_tags != null ? { for tag in local.lf_tags : tag => tag } : {}

  resource_arn       = "arn:aws:lakeformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:lf-tag/${each.key}"
  resource_share_arn = aws_ram_resource_share.lf_tag_share_apdp[0].arn
}

# =============================================================================
# DMS service-linked role (must be named exactly "dms-vpc-role") - TEST ONLY
#
# AWS DMS looks up this role by literal name when creating a replication subnet
# group. This is the test-account copy (the dms.tf one is is-development).
# The active claims pipeline (module.data_claims_dms in dms_data_claims.tf, task
# data-claims-cdc) sets manage_dms_service_roles = false and relies on this
# account-wide, fixed-name role existing.
# =============================================================================

resource "aws_iam_role" "access_dms_vpc_role" {
  count = local.is-test ? 1 : 0
  name  = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dms.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "access_dms_vpc_role" {
  count      = local.is-test ? 1 : 0
  role       = aws_iam_role.access_dms_vpc_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"

  # IAM propagation delay; DMS will reject the role until the attachment lands
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# ---------------------------------------------------------------------------
# DMS service-linked role (must be named exactly "dms-vpc-role")
# AWS DMS looks up this role by literal name when creating a replication
# subnet group. The upstream module creates one with name_prefix, which DMS
# does NOT find — so we create the literal-named role here.
# Refs: https://docs.aws.amazon.com/dms/latest/userguide/security-iam.APIRole.html
# ---------------------------------------------------------------------------
resource "aws_iam_role" "dms_vpc_role" {
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

resource "aws_iam_role_policy_attachment" "dms_vpc_role" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"

  # IAM propagation delay; DMS will reject the role until the attachment lands
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

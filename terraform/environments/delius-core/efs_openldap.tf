resource "aws_efs_file_system" "openldap" {
  creation_token = format("%s-openldap", local.application_name)
  tags = {
    Name = format("%s-openldap", local.application_name)
  }
}

resource "aws_security_group" "efs" {
  name        = format("%s-openldap-efs", local.application_name)
  description = format("%s-openldap-efs", local.application_name)
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_security_group_rule" "efs_ingress" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs.id
}

resource "aws_security_group_rule" "efs_egress" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs.id
}

module "s3_bucket_openldap_migration" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-openldap-migration"
  versioning_enabled = false

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

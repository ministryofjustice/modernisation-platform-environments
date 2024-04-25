# locals {
#   public_key_data = jsondecode(file("${path.module}/bastion_linux.json"))
# }

# # tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
# module "rds_bastion" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-bastion-linux?ref=v4.2.0"

#   providers = {
#     aws.share-host   = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
#     aws.share-tenant = aws          # The default provider (unaliased, `aws`) is the tenant
#   }

#   # s3 - used for logs and user ssh public keys
#   bucket_name = "rds-bastion"

#   # public keys
#   public_key_data = local.public_key_data.keys[local.environment]

#   # logs
#   log_auto_clean       = "Enabled"
#   log_standard_ia_days = 30  # days before moving to IA storage
#   log_glacier_days     = 60  # days before moving to Glacier
#   log_expiry_days      = 180 # days before log expiration

#   # bastion
#   allow_ssh_commands = true

#   app_name      = var.networking[0].application
#   business_unit = local.vpc_name
#   subnet_set    = local.subnet_set
#   environment   = local.environment
#   region        = "eu-west-2"

#   # tags
#   tags_common = local.tags
#   tags_prefix = terraform.workspace
# }

# resource "aws_vpc_security_group_egress_rule" "access_ms_sql_server" {
#   security_group_id = aws_security_group.ec2_bastion.id
#   description       = "EC2 MSSQL Access"
#   ip_protocol       = "tcp"
#   from_port         = 1433
#   to_port           = 1433
#   cidr_ipv4         = data.aws_vpc.shared.cidr_block
# }

# resource "aws_vpc_security_group_ingress_rule" "rds_via_vpc_access" {
#   security_group_id = aws_security_group.db.id
#   description       = "EC2 instance connection to RDS"
#   ip_protocol       = "tcp"
#   from_port         = 1433
#   to_port           = 1433
#   referenced_security_group_id = aws_security_group.ec2_bastion.id
# }

# resource "aws_iam_policy" "ec2_s3_policy" {
#   name        = "ec2-s3-policy"
#   description = "Policy for s3 actions"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = "s3:*",
#         Resource = ["*"]
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "s3_attachment" {
#   role       = module.rds_bastion.bastion_iam_role.name
#   policy_arn = aws_iam_policy.ec2_s3_policy.arn
# }


#------------------------------------------------------------------------------
# Security group rule addition
#------------------------------------------------------------------------------
resource "aws_security_group" "ec2_bastion_s3" {
  name        = "ec2-bastion-s3"
  description = "Allow ec2 access to s3"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_egress_rule" "s3_bast_vpc_access" {
  security_group_id = aws_security_group.ec2_bastion_s3.id
  description       = "Reach vpc endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "s3_bast_rds_access" {
  security_group_id            = aws_security_group.db.id
  description                  = "Ec2 instance"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = aws_security_group.ec2_bastion_s3.id
}

#------------------------------------------------------------------------------
# IAM to access database
#------------------------------------------------------------------------------

resource "aws_iam_role" "s3-ec2-instance" {
  name               = "s3-instance-role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.ec2-rds-access-role.json
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ec2-s3-policy"
  description = "Policy for s3 actions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.s3-ec2-instance.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

resource "aws_iam_instance_profile" "s3-ec2-instance" {
  name = "s3-instance-role"
  role = aws_iam_role.s3-ec2-instance.name
}

#------------------------------------------------------------------------------
# Instance definition
#------------------------------------------------------------------------------

resource "aws_instance" "s3_bastion_host" {
  ami                         = data.aws_ami.this.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.private_subnets_b.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.s3-ec2-instance.name
  security_groups             = [aws_security_group.ec2_bastion_s3.id]
  tags = merge(
    local.tags,
    { Name = "rds-s3-bastion" }
  )
}

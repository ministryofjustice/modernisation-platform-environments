# This contains the resources required to build the maatdb rds instance plus associated resources.

#TODO 1) Get ARN for the Shared Key and apply for snapshots & PI.
#TODO 2) Snapshot ARN in the vars


# tflint-ignore: terraform_required_version
terraform {}

# RDS Subnet Group

resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnet-group"
  subnet_ids = [var.vpc_subnet_a_id, var.vpc_subnet_b_id, var.vpc_subnet_c_id]

  tags = {
    Name = "${var.application_name}-${var.environment}-subnet-group"
  }
}


# RDS Parameter group

resource "aws_db_parameter_group" "parameter_group_19" {
  name        = "parameter-group-19"
  family      = "oracle-se2-19"
  description = "${var.application_name}-${var.environment}-parameter-group"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  parameter {
    name  = "db_cache_size"
    value = "2000000000"
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-parameter-group"
  }

}



# RDS Option group

#TODO - These settings are for MAATDB only so we need to consider whether they should be in the module or not.

resource "aws_db_option_group" "appdboptiongroup19" {
  name                     = "appdboptiongroup19"
  option_group_description = "${var.application_name}-${var.environment}-optiongroup"
  engine_name              = var.engine
  major_engine_version     = "19"

  option {
    option_name = "STATSPACK"
  }

  option {
    option_name = "UTL_MAIL"
  }

  option {
    option_name = "Timezone"
  }

  option {
    option_name = "APEX"
    version     = "21.1.v1"
  }

  option {
    option_name = "APEX-DEV"
  }

  dynamic "option" {
    for_each = trimspace(var.hub20_s3_bucket) != "" ? [1] : []
    content {
      option_name = "S3_INTEGRATION"
    }
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-optiongroup"
  }

}


# Random Secret for the DB Password.

# tflint-ignore: terraform_required_providers
resource "random_password" "rds_password" {
  length  = 12
  special = false
}

# TODO: Setup secret rotation and kms encryption of secret
resource "aws_secretsmanager_secret" "rds_password_secret" {
  #checkov:skip=CKV2_AWS_57:"This is will be fixed at a later date"
  #checkov:skip=CKV_AWS_149:"To be added later."
  name = "${var.application_name}-${var.environment}-rds_password_secret"
}


resource "aws_secretsmanager_secret_version" "rds_password_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_password_secret.id
  secret_string = jsonencode(
    {
      username = var.username
      password = random_password.rds_password.result
    }
  )
}

# From Vincent's PR
# TODO Rotation of secret which requires Lambda function created and permissions granted to Lambda to rotate.
#
# resource "aws_secretsmanager_secret_rotation" "rds_password-rotation" {
#   secret_id           = aws_secretsmanager_secret.rds_password_secret.id
#   rotation_lambda_arn = aws_lambda_function.<<<<example.arn>>>>>>
#
#   rotation_rules {
#     automatically_after_days = var.db_password_rotation_period
#   }
# }


# Consolidate security group IDs
# RDS database
locals {
  rds_sg_group_ids = compact([
    aws_security_group.cloud_platform_sec_group.id,
    aws_security_group.bastion_sec_group.id,
    aws_security_group.vpc_sec_group.id,
    aws_security_group.mlra_ecs_sec_group.id,
    aws_security_group.ses_sec_group.id,
    aws_security_group.mojfin_sec_group.id
  ])
}

# RDS database

# TODO: Ensure logging is enabled for the database and performance insights logs are encrypted
resource "aws_db_instance" "appdb1" {
  #checkov:skip=CKV_AWS_129:"To be addressed"
  #checkov:skip=CKV_AWS_354:"To be addressed"
  #checkov:skip=CKV_AWS_118:"Enhanced security not required"
  #checkov:skip=CKV_AWS_157:"Multi-az is enabled"
  #checkov:skip=CKV_AWS_133:"Nightly backup is enabled"
  #checkov:skip=CKV_AWS_353:"Performance Insights are enabled"
  #checkov:skip=CKV_AWS_226:"Minor upgrades disabled to ensure compatibility"
  #checkov:skip=CKV_AWS_293:"Deletion protection is enabled but not being recognised"

  port                                  = var.port
  allocated_storage                     = var.allocated_storage
  db_name                               = var.application_name
  identifier                            = "${var.identifier_name}-${var.environment}-database"
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  storage_type                          = var.storage_type
  iops                                  = var.iops
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  maintenance_window                    = var.maintenance_window
  character_set_name                    = var.character_set_name
  multi_az                              = var.multi_az
  username                              = var.username
  password                              = random_password.rds_password.result
  vpc_security_group_ids                = local.rds_sg_group_ids
  skip_final_snapshot                   = false
  final_snapshot_identifier             = "${var.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}-finalsnapshot"
  parameter_group_name                  = aws_db_parameter_group.parameter_group_19.name
  option_group_name                     = aws_db_option_group.appdboptiongroup19.name
  db_subnet_group_name                  = aws_db_subnet_group.subnet_group.name
  license_model                         = var.license_model
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  deletion_protection                   = var.deletion_protection
  copy_tags_to_snapshot                 = true
  storage_encrypted                     = true
  kms_key_id                            = var.kms_key_arn
  apply_immediately                     = true
  snapshot_identifier                   = var.snapshot_arn
  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    var.tags
  )

  timeouts {
    create = "60m"
    delete = "2h"
  }

}

# Access from Cloud Platform
resource "aws_security_group" "cloud_platform_sec_group" {
  #checkov:skip=CKV2_AWS_5:"Not applicable"
  name        = "cloud-platform-sec-group"
  description = "RDS access from Cloud Platform via Transit gateway"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.cloud_platform_cidr]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.cloud_platform_cidr]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-transit-gateway-sec-group"
  }
}

resource "aws_security_group" "vpc_sec_group" {
  #checkov:skip=CKV2_AWS_5:"Not applicable"
  name        = "ecs-sec-group"
  description = "RDS Access with the shared vpc"
  vpc_id      = var.vpc_shared_id

  # Ingress and egress with the maat application
  ingress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.ecs_cluster_sec_group_id]
  }

  egress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.ecs_cluster_sec_group_id]
  }

  # Required to support https calls from the RDS to the S3 endpoint. Note that vpc endpoint times out hence general outbound
  egress {
    description = "Access to S3 VPC endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "${var.application_name}-${var.environment}-vpc-sec-group"
  }
}

resource "aws_security_group" "mlra_ecs_sec_group" {
  #checkov:skip=CKV2_AWS_5:"Not applicable"
  name        = "mlra-ecs-sec-group"
  description = "RDS Access from the MLRA application"
  vpc_id      = var.vpc_shared_id

  ingress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.mlra_ecs_cluster_sec_group_id]
  }

  dynamic "ingress" {
    for_each = trimspace(var.hub20_sec_group_id) != "" ? [1] : []
    content {
      description     = "RDS Access from the HUB 2.0 MAAT Lambda"
      from_port       = 1521
      to_port         = 1521
      protocol        = "tcp"
      security_groups = [var.hub20_sec_group_id]
    }
  }

  egress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.mlra_ecs_cluster_sec_group_id]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-mlra-ecs-sec-group"
  }
}

# Access from Bastion

# tflint-ignore: terraform_required_providers
resource "aws_security_group" "bastion_sec_group" {
  #checkov:skip=CKV2_AWS_5:"Not applicable"
  name        = "bastion-sec-group"
  description = "Bastion Access with the shared vpc"
  vpc_id      = var.vpc_shared_id

  ingress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  egress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-bastion-sec-group"
  }
}

# Outbound to Port 587 for SES SMTP Endpoint Access

# tflint-ignore: terraform_required_providers
resource "aws_security_group" "ses_sec_group" {
  #checkov:skip=CKV2_AWS_5:"Not applicable"
  name        = "ses-sec-group"
  description = "SES Outbound Access"
  vpc_id      = var.vpc_shared_id

  egress {
    description = "SMTP Outbound to 587"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-ses-sec-group"
  }
}

resource "aws_security_group" "mojfin_sec_group" {
  name = "mojfin-sec-group"
  description = "Access from Mojfin"
  vpc_id      = var.vpc_shared_id

  ingress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.mojfin_sec_group_id]
  }

  egress {
    description     = "Sql Net on 1521"
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [var.mojfin_sec_group_id]
  }

  tags = {
    Name = "${var.application_name}-${var.environment}-mojfin-sec-group"
  }
}


#RDS role to access HUB 2.0 S3 Bucket
resource "aws_iam_role" "rds_s3_access" {
  count = trimspace(var.hub20_s3_bucket) != "" ? 1 : 0
  name  = "rds-hub20-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "rds_s3_access_policy" {
  count       = trimspace(var.hub20_s3_bucket) != "" ? 1 : 0
  name        = "rds-hub20-s3-bucket-policy"
  description = "Allow Oracle RDS instance to read objects from HUB 2.0 S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = [
          "arn:aws:s3:::${var.hub20_s3_bucket}",
          "arn:aws:s3:::${var.hub20_s3_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_access_policy_attachment" {
  count      = trimspace(var.hub20_s3_bucket) != "" ? 1 : 0
  role       = aws_iam_role.rds_s3_access[0].name
  policy_arn = aws_iam_policy.rds_s3_access_policy[0].arn
}

resource "aws_db_instance_role_association" "rds_s3_role_association" {
  count                  = trimspace(var.hub20_s3_bucket) != "" ? 1 : 0
  db_instance_identifier = aws_db_instance.appdb1.identifier
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.rds_s3_access[0].arn
}

# Outputs

output "db_instance_id" {
  value = aws_db_instance.appdb1.id
}




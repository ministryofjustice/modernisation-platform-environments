# This contains the resources required to build the maatdb rds instance plus associated resources.


# RDS Subnet Group


resource "aws_db_subnet_group" "appdbsubnetgroup" {
  name       = "${var.application_name}-${var.environment}-dbsubnetgroup"
  subnet_ids = var.db_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-${var.environment}-dbsubnetgroup",
    }
  )

}



# RDS Parameter group

resource "aws_db_parameter_group" "appdbparametergroup19" {
  name        = "${var.application_name}-${var.environment}-dbparametergroup19"
  family      = var.db_family
  description = "MAATDB 19c Parameter Group"

  parameter {
    name  = "remote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-${var.environment}-dbparametergroup19",
    }
  )

}



# RDS Option group

resource "aws_db_option_group" "appdboptiongroup19" {
  name                     = "${var.application_name}-${var.environment}-dboptiongroup19"
  option_group_description = "MAATDB 19c Option Group"
  engine_name              = var.db_engine
  major_engine_version     = var.db_engine_version

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

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-${var.environment}-dboptiongroup19",
    }
  )

}


# RDS database

resource "aws_db_instance" "appdb1" {
  allocated_storage                     = 10
  db_name                               = "${var.application_name}-${var.environment}-maatdb"
  engine                                = var.db_engine
  engine_version                        = var.db_full_engine_version
  instance_class                        = var.db_instance_class
  allow_major_version_upgrade           = true
  auto_minor_version_upgrade            = true
  storage_type                          = var.db_storage_type
  iops                                  = var.db_storage_iops
  backup_retention_period               = var.db_backup_retention_period
  backup_window                         = "22:00-01:00"
  maintenance_window                    = "Mon:01:15-Mon:06:00"
  character_set_name                    = "WE8MSWIN1252"
  multi_az                              = true
  username                              = var.db_admin_username
  password                              = random_password.rds_password.result
  vpc_security_group_ids                = [aws_security_group.appdb-secgroup.id]
  skip_final_snapshot                   = false
  parameter_group_name                  = aws_db_parameter_group.appdbparametergroup19.name
  option_group_name                     = aws_db_option_group.appdboptiongroup19.name
  db_subnet_group_name                  = aws_db_subnet_group.appdbsubnetgroup.name
  license_model                         = "license-included"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  deletion_protection                   = true
  copy_tags_to_snapshot                 = true
  storage_encrypted                     = true
  enabled_cloudwatch_logs_exports       = ["general", "error", "slowquery"]
  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-${var.environment}-maatdb",
    }
  )

}

# CLOUDFORMATION FOR REFERENCE
# AppDb1:
#   Type: AWS::RDS::DBInstance
#   DeletionPolicy: Snapshot
#   Properties:
#     AllocatedStorage: !Ref pAllocatedStorage
#     allow_major_version_upgrade: True
#     AutoMinorVersionUpgrade: false
#     StorageType: !Ref pRdsStorageType
#     Iops: !Ref pRdsIops
#     BackupRetentionPeriod: 35
#     PreferredBackupWindow: "22:00-01:00"
#     PreferredMaintenanceWindow: "Mon:01:15-Mon:06:00"
#     CharacterSetName: "WE8MSWIN1252"
#     VPCSecurityGroups:
#     - Ref: AppDbSecurityGroup
#     DBInstanceClass: !Ref pRdsInstanceType
#     DBName: !Ref pAppName
#     Engine: !Ref pDatabaseEngine
#     EngineVersion: !Ref pEngineVersion
#     MultiAZ: !Ref pFullRedundancy
#     MasterUsername: admin
#     MasterUserPassword: !Ref pAppMasterPassword
#     LicenseModel: license-included
#     DBSubnetGroupName: !Ref AppDbSubnetGroup
#     OptionGroupName: !Ref AppDbOptionGroup19
#     DBParameterGroupName: !Ref AppDbParameterGroup19
#     DBSnapshotIdentifier: !Ref pDBSnapshotIdentifier
#     CopyTagsToSnapshot: true
#     EnablePerformanceInsights: true
#     Tags:
#       - Key: Name
#         Value: !Ref pAppName
#



# Security Group

resource "aws_security_group" "appdb-secgroup" {
  name        = "${var.application_name}-${var.environment}-db-secgroup"
  description = "RDS DB Security Group"
  vpc_id      = var.db_vpc_id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.202.0.0/20"] #TODO Not sure where this cidr range come from so not parametrised or referenced yet
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.202.0.0/20"] #TODO Not sure where this cidr range come from so not parametrised or referenced yet
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-${var.environment}-db-secgroup",
    }
  )
}


# Setting credentials for RDS and store in Secret Manager

resource "random_password" "rds_password" {
  length  = 30
  special = false
}

resource "aws_secretsmanager_secret" "db_admin_password" {
  name = "${var.application_name}-${var.environment}-maatdb-admin-password"
}

resource "aws_secretsmanager_secret_version" "db_admin_password_version" {
  secret_id = aws_secretsmanager_secret.db_admin_password.id
  secret_string = jsonencode(
    {
      username = var.db_admin_username
      password = random_password.rds_password.result
    }
  )
}

# TODO Rotation of secret which requires Lambda fucntion created and permissions granted to Lambda to rotate
#
# resource "aws_secretsmanager_secret_rotation" "db_password" {
#   secret_id           = aws_secretsmanager_secret.db_admin_password.id
#   rotation_lambda_arn = aws_lambda_function.example.arn
#
#   rotation_rules {
#     automatically_after_days = var.db_password_rotation_period
#   }
# }

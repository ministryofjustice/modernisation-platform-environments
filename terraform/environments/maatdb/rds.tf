# This contains the resources required to build the maatdb rds instance plus associated resources.


# RDS Subnet Group


resource "aws_db_subnet_group" "appdbsubnetgroup" {
  name       = "appdbsubnetgroup"
  subnet_ids = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]

  tags = {
    Name = "maatdb-subnetgroup"
  }
}



# RDS Parameter group

resource "aws_db_parameter_group" "appdbparametergroup19" {
  name        = "appdbparametergroup19"
  family      = "oracle-se2-19"
  description = "MAATDB 19c Parameter Group"

  parameter {
    name  = "emote_dependencies_mode"
    value = "SIGNATURE"
  }

  parameter {
    name  = "sqlnetora.sqlnet.allowed_logon_version_server"
    value = "10"
  }

  tags = {
    Name = "maatdb19c-parametergroup"
  }

}



# RDS Option group

resource "aws_db_option_group" "appdboptiongroup19" {
  name                     = "appdboptiongroup19"
  option_group_description = "MAATDB 19c Option Group"
  engine_name              = "oracle-se2"
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

  tags = {
    Name = "maatdb19c-optiongroup"
  }

}


# RDS database

resource "aws_db_instance" "appdb1" {
  allocated_storage                     = 10
  db_name                               = "maatdb"
  engine                                = "oracle-se2"
  engine_version                        = "19.0.0.0.ru-2021-10.rur-2021-10.r1"
  instance_class                        = "db.t3.small"
  allow_major_version_upgrade           = true
  auto_minor_version_upgrade            = true
  storage_type                          = "gp2"
  iops                                  = 300
  backup_retention_period               = 35
  backup_window                         = "22:00-01:00"
  maintenance_window                    = "Mon:01:15-Mon:06:00"
  character_set_name                    = "WE8MSWIN1252"
  multi_az                              = true
  username                              = "admin"
  password                              = "development"
  vpc_security_group_ids                = [aws_security_group.appdb-secgroup.id]
  skip_final_snapshot                   = false
  parameter_group_name                  = "appdbparametergroup19"
  option_group_name                     = "appdboptiongroup19"
  db_subnet_group_name                  = "appdbsubnetgroup"
  license_model                         = "license-included"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  deletion_protection                   = true
  copy_tags_to_snapshot                 = true
  storage_encrypted                     = true
  enabled_cloudwatch_logs_exports       = ["general", "error", "slowquery"]
  tags = {
    Name = "maatdb19c database"
  }

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
  name        = "appdb-secgroup"
  description = "RDS DB Security Group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.202.0.0/20"]
  }

  egress {
    description = "Sql Net on 1521"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["10.202.0.0/20"]
  }

  tags = {
    Name = "appdb-secgroup"
  }
}

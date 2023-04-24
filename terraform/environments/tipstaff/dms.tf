provider "aws" {
  region     = "eu-west-2"
  access_key = jsondecode(data.aws_secretsmanager_secret_version.dms_source_credentials.secret_string)["ACCESS_KEY"]
  secret_key = jsondecode(data.aws_secretsmanager_secret_version.dms_source_credentials.secret_string)["SECRET_KEY"]
  alias      = "tacticalproducts"
}

resource "aws_dms_endpoint" "source" {
  database_name = "tipstaff_staging"
  endpoint_id   = "tipstaff-source"
  endpoint_type = "source"
  engine_name   = "postgres"
  username      = jsondecode(data.aws_secretsmanager_secret_version.dms_source_credentials.secret_string)["DTS-STAGING-DB-MASTER-USER"]
  password      = jsondecode(data.aws_secretsmanager_secret_version.dms_source_credentials.secret_string)["DTS-STAGING-DB-MASTER-PASSWORD"]
  port          = 5432
  server_name   = jsondecode(data.aws_secretsmanager_secret_version.dms_source_credentials.secret_string)["DTS-STAGING-DB-HOSTNAME"]
  ssl_mode      = "none"
}

resource "aws_dms_endpoint" "target" {
  depends_on = [aws_db_instance.tipstaff_db]

  database_name = local.application_data.accounts[local.environment].db_name
  endpoint_id   = "tipstaff-target"
  endpoint_type = "target"
  engine_name   = "postgres"
  password      = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["TIPSTAFF_DB_PASSWORD_DEV"]
  port          = 5432
  server_name   = aws_db_instance.tipstaff_db.address
  ssl_mode      = "none"
  username      = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["TIPSTAFF_DB_USERNAME_DEV"]
}

resource "aws_dms_replication_instance" "tipstaff_replication_instance" {
  allocated_storage          = 100
  apply_immediately          = true
  availability_zone          = "eu-west-2a"
  engine_version             = "3.4.7"
  multi_az                   = false
  publicly_accessible        = true
  auto_minor_version_upgrade = true
  replication_instance_class = "dms.t3.large"
  replication_instance_id    = "tipstaff_replication_instance"
}

resource "aws_dms_replication_task" "tipstaff_migration_task" {
  depends_on = [null_resource.setup_target_rds_security_group, aws_db_instance.tipstaff_db, aws_dms_endpoint.target, aws_dms_endpoint.source, aws_dms_replication_instance.tipstaff_replication_instance]

  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.tipstaff_replication_instance.replication_instance_arn
  replication_task_id       = "tipstaff_migration_task"
  replication_task_settings = "{\"FullLoadSettings\": {\"TargetTablePrepMode\": \"TRUNCATE_BEFORE_LOAD\"}}"
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  table_mappings            = "{\"rules\":[{\"rule-type\":\"selection\",\"rule-id\":\"1\",\"rule-name\":\"1\",\"object-locator\":{\"schema-name\":\"dbo\",\"table-name\":\"%\"},\"rule-action\":\"include\"}]}"
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  start_replication_task    = true
}

resource "aws_security_group" "dms_access_rule" {
  name        = "dms_access_rule"
  description = "allow dms access to the database"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allow DMS to connect to source database"
    cidr_blocks = ["${aws_dms_replication_instance.tipstaff_replication_instance.replication_instance_public_ips[0]}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  provider = aws.tacticalproducts

}

resource "null_resource" "setup_target_rds_security_group" {
  depends_on = [aws_dms_replication_instance.tipstaff_replication_instance]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-security-group.sh; ./setup-security-group.sh"

    environment = {
      DMS_SECURITY_GROUP            = aws_security_group.dms_access_rule.id
      DMS_TARGET_ACCOUNT_ACCESS_KEY = aws.tacticalproducts.access_key
      DMS_TARGET_ACCOUNT_SECRET_KEY = aws.tacticalproducts.secret_key
      DMS_TARGET_ACCOUNT_REGION     = aws.tacticalproducts.region
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

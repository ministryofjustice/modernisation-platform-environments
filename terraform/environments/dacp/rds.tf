# trivy:ignore:AVD-AWS-0080
resource "aws_db_instance" "dacp_db" {
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances" - false error
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_293: "Ensure that AWS database instances have deletion protection enabled"
  #checkov:skip=CKV_AWS_353: "Ensure that RDS instances have performance insights enabled"
  #checkov:skip=CKV_AWS_354: "Ensure RDS Performance Insights are encrypted using KMS CMKs"
  count                           = local.is-development ? 0 : 1
  allocated_storage               = local.application_data.accounts[local.environment].allocated_storage
  db_name                         = local.application_data.accounts[local.environment].db_name
  storage_type                    = local.application_data.accounts[local.environment].storage_type
  engine                          = local.application_data.accounts[local.environment].engine
  identifier                      = local.application_data.accounts[local.environment].identifier
  engine_version                  = local.application_data.accounts[local.environment].engine_version
  instance_class                  = local.application_data.accounts[local.environment].instance_class
  username                        = local.application_data.accounts[local.environment].db_username
  password                        = random_password.password.result
  skip_final_snapshot             = true
  publicly_accessible             = false
  vpc_security_group_ids          = [aws_security_group.postgresql_db_sc[0].id]
  db_subnet_group_name            = aws_db_subnet_group.dbsubnetgroup.name
  allow_major_version_upgrade     = false
  auto_minor_version_upgrade      = true
  ca_cert_identifier              = "rds-ca-rsa2048-g1"
  apply_immediately               = true
  copy_tags_to_snapshot           = true
  parameter_group_name            = local.is_production ? "default.postgres14" : aws_db_parameter_group.dacp_analyse.name
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}

# 1. Create a custom parameter group
resource "aws_db_parameter_group" "dacp_analyse" {
  name        = "custom-postgres-parameters"
  family      = "postgres14"   # match your RDS engine version
  description = "Custom parameter group for slow query logging"

  parameter {
    name  = "log_min_duration_statement"
    value = "5000"   # log queries longer than 5 seconds
  }

  parameter {
    name  = "log_statement"
    value = "none"
  }

  parameter {
    name  = "log_destination"
    value = "stderr"
  }
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}


resource "aws_security_group" "postgresql_db_sc" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  count       = local.is-development ? 0 : 1
  name        = "postgres_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Allows ECS service to access RDS"
    security_groups = [aws_security_group.ecs_service.id]
  }

  ingress {
    protocol    = "tcp"
    description = "Allow PSQL traffic from bastion"
    from_port   = 5432
    to_port     = 5432
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  egress {
    #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

// DB setup for the development environment (set to publicly accessible to allow GitHub Actions access):
resource "aws_db_instance" "dacp_db_dev" {
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV_AWS_17: "Ensure all data stored in RDS is not publicly accessible" - see above
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances"
  #checkov:skip=CKV_AWS_129: "Ensure that respective logs of Amazon Relational Database Service (Amazon RDS) are enabled"
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_293: "Ensure that AWS database instances have deletion protection enabled"
  #checkov:skip=CKV_AWS_353: "Ensure that RDS instances have performance insights enabled"
  count                       = local.is-development ? 1 : 0
  allocated_storage           = local.application_data.accounts[local.environment].allocated_storage
  db_name                     = local.application_data.accounts[local.environment].db_name
  storage_type                = local.application_data.accounts[local.environment].storage_type
  engine                      = local.application_data.accounts[local.environment].engine
  identifier                  = local.application_data.accounts[local.environment].identifier
  engine_version              = local.application_data.accounts[local.environment].engine_version
  instance_class              = local.application_data.accounts[local.environment].instance_class
  username                    = local.application_data.accounts[local.environment].db_username
  password                    = random_password.password.result
  skip_final_snapshot         = true
  publicly_accessible         = true
  vpc_security_group_ids      = [aws_security_group.postgresql_db_sc_dev[0].id]
  db_subnet_group_name        = aws_db_subnet_group.dbsubnetgroup.name
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  copy_tags_to_snapshot       = true
}

resource "aws_security_group" "postgresql_db_sc_dev" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  count       = local.is-development ? 1 : 0
  name        = "postgres_security_group_dev"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Allows ECS service to access RDS"
    security_groups = [aws_security_group.ecs_service.id]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allows Github Actions to access RDS"
    cidr_blocks = ["${jsondecode(data.http.myip.response_body)["ip"]}/32"]
  }

  ingress {
    protocol    = "tcp"
    description = "Allow PSQL traffic from bastion"
    from_port   = 5432
    to_port     = 5432
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }
  egress {
    #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

data "http" "myip" {
  url = "http://ipinfo.io/json"
}

resource "null_resource" "setup_db" { # tflint-ignore: terraform_required_providers
  count = local.is-development ? 1 : 0

  depends_on = [aws_db_instance.dacp_db_dev[0]]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-dev-db.sh; ./setup-dev-db.sh"

    environment = {
      DB_HOSTNAME      = aws_db_instance.dacp_db_dev[0].address
      DB_NAME          = aws_db_instance.dacp_db_dev[0].db_name
      DACP_DB_USERNAME = aws_db_instance.dacp_db_dev[0].username
      DACP_DB_PASSWORD = random_password.password.result
    }
  }
  triggers = {
    always_run = timestamp()
  }
}

resource "aws_cloudwatch_log_group" "rds_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that Cloudwatch Log Group is encrypted using KMS CMK"
  name              = "/aws/events/rdsLogs"
  retention_in_days = "7"
}

# AWS EventBridge rule for RDS events
resource "aws_cloudwatch_event_rule" "rds_events" {
  count       = local.is-development ? 0 : 1
  name        = "rds-events"
  description = "Capture all RDS events"

  event_pattern = jsonencode({
    "source" : ["aws.rds"],
    "detail" : {
      "eventSource" : ["db-instance"],
      "resources" : [aws_db_instance.dacp_db[0].arn]
    }
  })
}

# AWS EventBridge target for RDS events
resource "aws_cloudwatch_event_target" "rds_logs" {
  depends_on = [aws_cloudwatch_log_group.rds_logs]
  count      = local.is-development ? 0 : 1
  rule       = aws_cloudwatch_event_rule.rds_events[0].name
  target_id  = "send-to-cloudwatch"
  arn        = aws_cloudwatch_log_group.rds_logs.arn
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "rds-connections-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "50" # Set desired threshold for high connections
  alarm_description   = "This metric checks if RDS database connections are high - threshold set to 50"
  alarm_actions       = [aws_sns_topic.dacp_utilisation_alarm.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.dacp_db[0].identifier
  }
}

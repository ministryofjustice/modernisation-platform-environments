resource "aws_db_instance" "dacp_db" {
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
  vpc_security_group_ids      = [aws_security_group.postgresql_db_sc.id]
  db_subnet_group_name        = aws_db_subnet_group.dbsubnetgroup.name
  allow_major_version_upgrade = true
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

resource "aws_security_group" "postgresql_db_sc" {
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

resource "null_resource" "setup_db" {
  count = local.is-development ? 1 : 0

  depends_on = [aws_db_instance.dacp_db]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "chmod +x ./setup-dev-db.sh; ./setup-dev-db.sh"

    environment = {
      DB_HOSTNAME      = aws_db_instance.dacp_db.address
      DB_NAME          = aws_db_instance.dacp_db.db_name
      DACP_DB_USERNAME = aws_db_instance.dacp_db.username
      DACP_DB_PASSWORD = random_password.password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/aws/events/rdsLogs"
  retention_in_days = "7"
}

# AWS EventBridge rule for RDS events
resource "aws_cloudwatch_event_rule" "rds_events" {
  name        = "rds-events"
  description = "Capture all RDS events"

  event_pattern = jsonencode({
    "source" : ["aws.rds"],
    "detail" : {
      "eventSource" : ["db-instance"],
      "resources" : [aws_db_instance.dacp_db.arn]
    }
  })
}

# AWS EventBridge target for RDS events
resource "aws_cloudwatch_event_target" "rds_logs" {
  depends_on = [aws_cloudwatch_log_group.rds_logs]
  rule       = aws_cloudwatch_event_rule.rds_events.name
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
  threshold           = "60"  # Set desired threshold for high connections
  alarm_description   = "This metric checks if RDS database connections are high - threshold set to 60"
  alarm_actions       = [aws_sns_topic.dacp_utilisation_alarm[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.dacp_db.identifier
  }
}

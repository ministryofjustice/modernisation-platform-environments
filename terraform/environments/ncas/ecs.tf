resource "aws_ecs_cluster" "ncas_cluster" {
  name = "ncas_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "deployment_logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  name              = "/aws/events/deploymentLogs"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  # checkov:skip=CKV_AWS_158: "CloudWatch log group is not public facing, does not contain any sensitive information and does not need encryption"
  name              = "ncas-ecs"
  retention_in_days = "7"
}

resource "aws_ecs_task_definition" "ncas_task_definition" {
  family                   = "ncasFamily"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name                   = "ncas-container"
      image                  = "${aws_ecr_repository.ncas_ecr_repo.repository_url}:latest"
      cpu                    = 1024
      memory                 = 2048
      essential              = true
      ReadonlyRootFilesystem = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name,
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "ncas-app"
        }
      },
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "RDS_HOSTNAME"
          value = aws_db_instance.ncas_db.address
        },
        {
          name  = "RDS_PORT"
          value = local.application_data.accounts[local.environment].rds_port
        },
        {
          name  = "RDS_USERNAME"
          value = aws_db_instance.ncas_db.username
        },
        {
          name  = "RDS_PASSWORD"
          value = aws_db_instance.ncas_db.password
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.ncas_db.db_name
        },
        {
          name  = "supportEmail"
          value = local.application_data.accounts[local.environment].support_email
        },
        {
          name  = "supportTeam"
          value = local.application_data.accounts[local.environment].support_team
        },
        {
          name  = "ida:ClientId"
          value = local.application_data.accounts[local.environment].client_id
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2022_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "ncas_ecs_service" {
  depends_on = [
    aws_lb_listener.ncas_lb
  ]

  name                              = "${var.networking[0].application}-win2022"
  cluster                           = aws_ecs_cluster.ncas_cluster.id
  task_definition                   = aws_ecs_task_definition.ncas_task_definition.arn
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  desired_count                     = 2
  health_check_grace_period_seconds = 180
  force_new_deployment              = true

  network_configuration {
    subnets          = data.aws_subnets.shared-private.ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ncas_target_group.arn
    container_name   = "ncas-container"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "app_execution" {
  name = "execution-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "execution-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_execution" {
  name = "execution-${var.networking[0].application}"
  role = aws_iam_role.app_execution.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
               "logs:CreateLogStream",
               "logs:PutLogEvents"
           ],
           "Resource": [
               "${aws_cloudwatch_log_group.deployment_logs.arn}",
               "${aws_cloudwatch_log_group.deployment_logs.arn}:*",
               "${aws_cloudwatch_log_group.ecs_logs.arn}",
                "${aws_cloudwatch_log_group.ecs_logs.arn}:*"
           ],
           "Effect": "Allow"
      },
      {
            "Action": [
              "ecr:GetAuthorizationToken"
            ],
            "Resource": "*",
            "Effect": "Allow"
      },
      {
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage"
            ],
            "Resource": "arn:aws:ecr:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:repository/${aws_ecr_repository.ncas_ecr_repo.name}",
            "Effect": "Allow"
      },
      {
          "Action": [
               "secretsmanager:GetSecretValue"
           ],
          "Resource": "arn:aws:secretsmanager:*:${local.environment_management.account_ids[terraform.workspace]}:secret:${aws_secretsmanager_secret.rds_db_credentials.arn}",
          "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "app_task" {
  name = "task-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "task-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_task" {
  name = "task-${var.networking[0].application}"
  role = aws_iam_role.app_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups"
        ],
        "Resource": "arn:aws:logs:*:${local.environment_management.account_ids[terraform.workspace]}:*",
        "Effect": "Allow"
     }
   ]
  }
  EOF
}

resource "aws_security_group" "ecs_service" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  name_prefix = "ecs-service-sg-"
  description = "control access to the ECS service"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [aws_security_group.ncas_lb_sc.id]
  }

  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "ncas_ecr_repo" {
  #checkov:skip=CKV_AWS_51: "Ensure ECR Image Tags are immutable"
  #checkov:skip=CKV_AWS_136:"Using default AWS encryption for ECR which is sufficient for our needs"
  name         = "ncas-ecr-repo"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# AWS EventBridge rule
resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "ecs-events"
  description = "Capture all ECS events"

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail" : {
      "clusterArn" : [aws_ecs_cluster.ncas_cluster.arn]
    }
  })
}

# AWS EventBridge target
resource "aws_cloudwatch_event_target" "logs" {
  depends_on = [aws_cloudwatch_log_group.deployment_logs]
  rule       = aws_cloudwatch_event_rule.ecs_events.name
  target_id  = "send-to-cloudwatch"
  arn        = aws_cloudwatch_log_group.deployment_logs.arn
}

resource "aws_cloudwatch_log_resource_policy" "ecs_logging_policy" {
  policy_document = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "TrustEventsToStoreLogEvent",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
        },
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/events/*:*"
      }
    ]
  })
  policy_name = "TrustEventsToStoreLogEvents"
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "ecs-cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CpuUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric checks if CPU utilization is high - threshold set to 80%"
  alarm_actions       = [aws_sns_topic.ncas_utilisation_alarm[0].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ncas_cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_alarm" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "ecs-memory-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilized"
  namespace           = "ECS/ContainerInsights"
  period              = "120"
  statistic           = "Average"
  threshold           = "1600"
  alarm_description   = "This metric checks if memory utilization is high - threshold set to 1600MB"
  alarm_actions       = [aws_sns_topic.ncas_utilisation_alarm[0].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.ncas_cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_attack_external" {
  count               = local.is-development ? 0 : 1
  alarm_name          = "DDoSDetected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ddos_alarm[0].arn]
  dimensions = {
    ResourceArn = aws_lb.ncas_lb.arn
  }
}

resource "aws_sns_topic" "ddos_alarm" {
  # checkov:skip=CKV_AWS_26: SNS encryption not required for this use case
  count = local.is-development ? 0 : 1
  name  = "ncas_ddos_alarm"
}

resource "aws_sns_topic" "ncas_utilisation_alarm" {
  # checkov:skip=CKV_AWS_26: SNS encryption not required for this use case
  count = local.is-development ? 0 : 1
  name  = "ncas_utilisation_alarm"
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
}

# link the sns topic to the service - preprod
module "pagerduty_core_alerts_non_prod" {
  count = local.is-preproduction ? 1 : 0
  depends_on = [
    aws_sns_topic.ncas_utilisation_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=0179859e6fafc567843cd55c0b05d325d5012dc4" #v2.0.0
  sns_topics                = [aws_sns_topic.ncas_utilisation_alarm[0].name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ncas_non_prod_alarms"]
}

# link the sns topic to the service - prod
module "pagerduty_core_alerts_prod" {
  count = local.is-production ? 1 : 0
  depends_on = [
    aws_sns_topic.ncas_utilisation_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=0179859e6fafc567843cd55c0b05d325d5012dc4" #v2.0.0
  sns_topics                = [aws_sns_topic.ncas_utilisation_alarm[0].name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ncas_prod_alarms"]
}

resource "aws_ecs_cluster" "pra_cluster" {
  name = "pra_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "deployment_logs" {
  #checkov:skip=CKV_AWS_158:"Using default AWS encryption for CloudWatch logs which is sufficient for our needs"
  name              = "/aws/events/deploymentLogs"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  #checkov:skip=CKV_AWS_158:"Using default AWS encryption for CloudWatch logs which is sufficient for our needs"
  name              = "pra-ecs"
  retention_in_days = "7"
}

resource "aws_ecs_task_definition" "pra_task_definition" {
  family                   = "praFamily"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  cpu                      = 2048
  memory                   = 4096
  container_definitions = jsonencode([
    {
      name                   = "pra-container"
      image                  = "${aws_ecr_repository.pra_ecr_repo.repository_url}:latest"
      cpu                    = 2048
      memory                 = 4096
      essential              = true
      ReadonlyRootFilesystem = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name,
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "pra-app"
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
          value = aws_db_instance.pra_db.address
        },
        {
          name  = "RDS_PORT"
          value = local.application_data.accounts[local.environment].rds_port
        },
        {
          name  = "RDS_USERNAME"
          value = aws_db_instance.pra_db.username
        },
        {
          name  = "RDS_PASSWORD"
          value = random_password.password.result
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.pra_db.db_name
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
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "pra_ecs_service" {
  depends_on = [
    aws_lb_listener.pra_lb
  ]
  name                              = var.networking[0].application
  cluster                           = aws_ecs_cluster.pra_cluster.id
  task_definition                   = aws_ecs_task_definition.pra_task_definition.arn
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  desired_count                     = 2
  health_check_grace_period_seconds = 180

  network_configuration {
    subnets          = data.aws_subnets.shared-private.ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pra_target_group.arn
    container_name   = "pra-container"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
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

# This is the role ECS uses to manage the task
# needed by the ECS agent / Fargate to Pull container images from ECR, Write logs, fetch secrets
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
            "Resource": "arn:aws:ecr:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:repository/${aws_ecr_repository.tipstaff_ecr_repo.name}",
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

# This is the role the application inside the container assumes at runtime
# Just logging for AWSLogger/NLog
resource "aws_iam_role_policy" "app_task" {
  name = "task-${var.networking[0].application}"
  role = aws_iam_role.app_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
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

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [aws_security_group.pra_lb_sc.id]
  }

  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "pra_ecr_repo" {
  #checkov:skip=CKV_AWS_51: "Ensure ECR Image Tags are immutable"
  #checkov:skip=CKV_AWS_136:"Using default AWS encryption for ECR which is sufficient for our needs"
  name         = "pra-ecr-repo"
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
      "clusterArn" : [aws_ecs_cluster.pra_cluster.arn]
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
  alarm_actions       = [aws_sns_topic.pra_utilisation_alarm[0].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.pra_cluster.name
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
  alarm_actions       = [aws_sns_topic.pra_utilisation_alarm[0].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.pra_cluster.name
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
    ResourceArn = aws_lb.pra_lb.arn
  }
}

resource "aws_sns_topic" "ddos_alarm" {
  # checkov:skip=CKV_AWS_26: SNS encryption not required for this use case
  count = local.is-development ? 0 : 1
  name  = "pra_ddos_alarm"
}

resource "aws_sns_topic" "pra_utilisation_alarm" {
  # checkov:skip=CKV_AWS_26: SNS encryption not required for this use case
  count = local.is-development ? 0 : 1
  name  = "pra_utilisation_alarm"
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
    aws_sns_topic.pra_utilisation_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=0179859e6fafc567843cd55c0b05d325d5012dc4" #v2.0.0
  sns_topics                = [aws_sns_topic.pra_utilisation_alarm[0].name]
  pagerduty_integration_key = local.pagerduty_integration_keys["pra_non_prod_alarms"]
}

# link the sns topic to the service - prod
module "pagerduty_core_alerts_prod" {
  count = local.is-production ? 1 : 0
  depends_on = [
    aws_sns_topic.pra_utilisation_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=0179859e6fafc567843cd55c0b05d325d5012dc4" #v2.0.0
  sns_topics                = [aws_sns_topic.pra_utilisation_alarm[0].name]
  pagerduty_integration_key = local.pagerduty_integration_keys["pra_prod_alarms"]
}

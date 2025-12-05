resource "aws_ecs_cluster" "dacp_cluster" {
  name = "dacp_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "deployment_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS
  name              = "/aws/events/deploymentLogs"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS
  name              = "dacp-ecs"
  retention_in_days = "7"
}

resource "aws_ecs_task_definition" "dacp_task_definition" {
  count                    = local.is-development ? 0 : 1
  family                   = "dacpFamily"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  cpu                      = local.application_data.accounts[local.environment].ecs_cpu
  memory                   = local.application_data.accounts[local.environment].ecs_memory
  container_definitions = jsonencode([
    {
      name                   = "dacp-container"
      image                  = "${aws_ecr_repository.dacp_ecr_repo.repository_url}:latest"
      cpu                    = local.application_data.accounts[local.environment].ecs_cpu
      memory                 = local.application_data.accounts[local.environment].ecs_memory
      essential              = true
      ReadonlyRootFilesystem = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name,
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "dacp-app"
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
          value = aws_db_instance.dacp_db[0].address
        },
        {
          name  = "RDS_PORT"
          value = local.application_data.accounts[local.environment].rds_port
        },
        {
          name  = "RDS_USERNAME"
          value = aws_db_instance.dacp_db[0].username
        },
        {
          name  = "RDS_PASSWORD"
          value = aws_db_instance.dacp_db[0].password
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.dacp_db[0].db_name
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
        },
        {
          name  = "BURY_COURT_ID"
          value = local.application_data.accounts[local.environment].bury_court_id
        },
        {
          name  = "BURY_POST_2015_SEND_CODE"
          value = local.application_data.accounts[local.environment].bury_post_2015_send_code
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2022_CORE"
    cpu_architecture        = "X86_64"
  }
}

//ECS task definition for the development environment:
resource "aws_ecs_task_definition" "dacp_task_definition_dev" {
  count                    = local.is-development ? 1 : 0
  family                   = "dacpFamily"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution.arn
  task_role_arn            = aws_iam_role.app_task.arn
  cpu                      = local.application_data.accounts[local.environment].ecs_cpu
  memory                   = local.application_data.accounts[local.environment].ecs_memory
  container_definitions = jsonencode([
    {
      name                   = "dacp-container"
      image                  = "${aws_ecr_repository.dacp_ecr_repo.repository_url}:latest"
      cpu                    = local.application_data.accounts[local.environment].ecs_cpu
      memory                 = local.application_data.accounts[local.environment].ecs_memory
      essential              = true
      ReadonlyRootFilesystem = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name,
          "awslogs-region"        = "eu-west-2",
          "awslogs-stream-prefix" = "dacp-app"
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
          value = aws_db_instance.dacp_db_dev[0].address
        },
        {
          name  = "RDS_PORT"
          value = local.application_data.accounts[local.environment].rds_port
        },
        {
          name  = "RDS_USERNAME"
          value = aws_db_instance.dacp_db_dev[0].username
        },
        {
          name  = "RDS_PASSWORD"
          value = aws_db_instance.dacp_db_dev[0].password
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.dacp_db_dev[0].db_name
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
        },
        {
          name  = "BURY_COURT_ID"
          value = local.application_data.accounts[local.environment].bury_court_id
        },
        {
          name  = "BURY_POST_2015_SEND_CODE"
          value = local.application_data.accounts[local.environment].bury_post_2015_send_code
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2022_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "dacp_ecs_service" {
  depends_on = [
    aws_lb_listener.dacp_lb
  ]
  count                             = local.is-development ? 0 : 1
  name                              = "${var.networking[0].application}-win2022"
  cluster                           = aws_ecs_cluster.dacp_cluster.id
  task_definition                   = aws_ecs_task_definition.dacp_task_definition[0].arn
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
    target_group_arn = aws_lb_target_group.dacp_target_group.arn
    container_name   = "dacp-container"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "dacp_ecs_service_dev" {
  depends_on = [
    aws_lb_listener.dacp_lb
  ]
  count                             = local.is-development ? 1 : 0
  name                              = "${var.networking[0].application}-win2022"
  cluster                           = aws_ecs_cluster.dacp_cluster.id
  task_definition                   = aws_ecs_task_definition.dacp_task_definition_dev[0].arn
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
    target_group_arn = aws_lb_target_group.dacp_target_group.arn
    container_name   = "dacp-container"
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
              "ecr:*",
              "logs:*",
              "secretsmanager:GetSecretValue"
           ],
           "Resource": "*",
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
       "Effect": "Allow",
        "Action": [
          "logs:*",
          "ecr:*",
          "iam:*",
          "ec2:*"
        ],
       "Resource": "*"
     }
   ]
  }
  EOF
}

resource "aws_security_group" "ecs_service" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  name_prefix = "ecs-service-sg-"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [aws_security_group.dacp_lb_sc.id]
  }

  egress {
    #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "dacp_ecr_repo" {
  #checkov:skip=CKV_AWS_136: "Ensure that ECR repositories are encrypted using KMS" - ignore
  #checkov:skip=CKV_AWS_51: "Ensure ECR Image Tags are immutable"
  name         = "dacp-ecr-repo"
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
      "clusterArn" : [aws_ecs_cluster.dacp_cluster.arn]
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
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = local.is-preproduction ? 1 : 0
  depends_on = [
    aws_sns_topic.dacp_utilisation_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.dacp_utilisation_alarm.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["dacp_non_prod_alarms"]
}

# link the sns topic to the service - prod
module "pagerduty_core_alerts_prod" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = local.is-production ? 1 : 0
  depends_on = [
    aws_sns_topic.dacp_utilisation_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.dacp_utilisation_alarm.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["dacp_prod_alarms"]
}

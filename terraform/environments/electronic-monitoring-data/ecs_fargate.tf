
# --------------------------------------------------
# ears sars cluster - just one for now
# --------------------------------------------------

resource "aws_ecs_cluster" "ears_sars_app" {
  name = "ear-sars-ecs-cluster"
  tags =  merge(
    local.tags
  )
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"
      kms_key_id = aws_kms_key.cloudwatch_log_group_key.arn

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs.name
      }
    }
  }
}

# --------------------------------------------------
# exceution role
# --------------------------------------------------

data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ears-sars-app-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------
# task role
# ---------------------------------------------------

data "aws_iam_policy_document" "ecs_task_policy" {
  #checkov:skip=CKV_AWS_356 - only for list my buckets
  #checkov:skip=CKV_AWS_111 - only for getting account aliases
  statement{
    effect  = "Allow"
    actions = [
        "s3:ListBucket",
    ]
    resources = [module.s3-export-bucket.bucket.arn]
  }
  statement{
    effect  = "Allow"
    actions = [
        "s3:PutObject",
    ]
    resources = ["${module.s3-export-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "AthenaPermissionsForEARSARs"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${data.aws_caller_identity.current.id}-default",
    ]
  }
  statement {
    sid    = "GetDataAccessAndTagsForLakeFormationForEARSARs"
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:GetResourceLFTags",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ListAccountAliasForEARSARs"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucketForEARSARs"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ears-sars-app-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}
resource "aws_iam_policy" "ecs_task_policy" {
  name = "ears-sars-app-ecs-task-role-policy"
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "/aws/ecs/ears-sars-app/cluster"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_log_group_key.arn
}

resource "aws_ecs_task_definition" "ears_sars_api" {
  family                   = "ears-sars-app-api-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = 2048
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name    = "ears-sars-app-api-container"
      image   = "v0.0.1"
      command = ["uv run main.py"]
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-stream-prefix = "ears-sars-app"
          awslogs-region        = "eu-west-2"
        }
      },
    readonlyRootFilesystem = true
    }
  ])
}

# ---------------------------------------------------
# security group
# ---------------------------------------------------

resource "aws_security_group" "ecs_service" {
  name_prefix = "ears_sars_sg"
  description = "Allow ecs to connect to sharepoint"

  vpc_id      = data.aws_vpc.shared.id
}

# uncomment when we have service now ip
# resource "aws_security_group_egress_rule" "sharepoint_access" {
#   security_group_id = aws_security_group.ecs_service.id
#   cidr_ipv4   = # insert servicenow ipv4 here
#   from_port   = 80
#   ip_protocol = "tcp"
#   to_port     = 80
# }


# ---------------------------------------------------
# Deployment
# ---------------------------------------------------

resource "aws_ecs_service" "ears_sars_api" {
  name            = "ears-sars-app-ecs-service"
  cluster         = aws_ecs_cluster.ears_sars_app.name
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.ears_sars_api.arn

  network_configuration {
    subnets         = data.aws_subnets.shared-private.ids
    security_groups = [aws_security_group.ecs_service.id]
  }
  

  lifecycle {
    ignore_changes = [desired_count]
  }
}

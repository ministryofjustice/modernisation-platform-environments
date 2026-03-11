locals {
  structured_data_image_name = "gdpr_structured_data"
  ecr_repo_name              = "electronic-monitoring-ear-sars"
  core_shared_services_id    = local.environment_management.account_ids["core-shared-services-production"]
}

data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_execution_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:*",
      "elasticloadbalancing:*",
      "cloudwatch:*",
      "logs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ears-sars-app-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}
resource "aws_iam_policy" "ecs_execution_policy" {
  name   = "ears-sars-app-ecs-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_role" "ecs_gdpr_execution_role" {
  name               = "emds-gdpr-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
}

resource "aws_iam_policy" "ecs_gdpr_execution_policy" {
  name   = "emds-gdpr-ecs-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}
resource "aws_iam_role_policy_attachment" "ecs_gdpr_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_gdpr_execution_policy.arn
}

data "aws_iam_policy_document" "gdpr_structured_job_policy_document" {
  statement {
    sid    = "AthenaQueryActions"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueMetadataAccess"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartitions",
      "glue:BatchDeletePartition"
    ]
     resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*"
    ]
  }

  statement {
    sid    = "S3DataAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      module.s3-data-bucket.bucket.bucket.arn,
      "${module.s3-data-bucket.bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role" "ecs_gdpr_structured_job_task_policy" {
  name               = "ecs-gdpr-structured-job-task-policy"
  assume_role_policy = data.aws_iam_policy_document.gdpr_structured_job_policy_document.json
}

resource "aws_ecs_cluster" "emds-gdpr-cluster" {
  count = local.is-development || local.is-preproduction ? 1 : 0
  name  = "emds-gdpr-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  count        = local.is-development || local.is-preproduction ? 1 : 0
  cluster_name = aws_ecs_cluster.example.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "emds-gdpr-structured-data-deletion" {
  count                    = local.is-development || local.is-preproduction ? 1 : 0
  family                   = "emds_gdpr_structured_data_deletion_family"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_gdpr_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "emds_gdpr_structured_data_deletion_job"
      image     = "${local.core_shared_services_id}.dkr.ecr.eu-west-2.amazonaws.com/${local.ecr_repo_name}:${local.structured_data_image_name}"
      cpu       = "1024"
      memory    = "2048"
      essential = "true"
      logConfiguration : {
        logDriver = "awslogs",
        options = {
          awslogs-create-group  = "true",
          awslogs-group         = "/ecs/ubuntu",
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs"
      } }
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
    },
  ])
}

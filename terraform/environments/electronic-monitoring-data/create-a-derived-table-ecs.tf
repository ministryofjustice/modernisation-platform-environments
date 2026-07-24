resource "aws_ecs_task_definition" "create_a_derived_table" {
  family = "create-a-derived-table"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu = 2048
  memory = 4096
 # leave this for now, but it should be in the lambda later
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/create-a-derived-table:hmpps_electronic_monitoring_data_tables-123"
      cpu       = 2048
      memory    = 4096
      essential = true
      logConfiguration : {
        logDriver = "awslogs",
        options = {
          awslogs-create-group  = "true",
          awslogs-group         = "/ecs/create-a-derived-table",
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs"
      } }
      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "REPOSITORY_PATH"
          value = "./create-a-derived-table"
        },
        {
          name  = "MODE"
          value = "build"
        },
        {
          name = "DBT_PROFILE_WORKGROUP"
          value = aws_athena_workgroup.cadt.name
        },
        {
          name = "DBT_PROJECT"
          value = "hmpps_electronic_monitoring_data_tables"
        },
        {
          name = "DBT_SELECT_CRITERIA"
          value = "tag:emd_live"
        },
        {
          name = "S3_BUCKET"
          value = module.s3-create-a-derived-table-bucket.bucket
        },
        {
          name = "STATE_MODE"
          value = "false"
        },
        {
          name = "WORKFLOW_NAME"
          value = "cadet-em-prod"
        },
        {
          name = "EM_REMOVE_HISTORIC"
          value = "true"
        },
        {
          name = "EM_REMOVE_LIVE"
          value = "false"
        },
        {
          name = "DBT_PROFILE"
          value = "emd"
        },
        {
          name = "DEPLOY_ENV"
          value = local.environment_shorthand
        }

      ]
    }
  ])
  task_role_arn = aws_iam_role.dataapi_cross_role.arn
  execution_role_arn = module.ecs_execution_role.arn

}

module "ecs_execution_role" {
 source  = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "ecs_execution_cadt"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "ecs-tasks.amazonaws.com",
        ]
      }]
    }
  }

  policies = {
    custom =  aws_iam_policy.ecs_execution_policy.arn
  }
  use_name_prefix = false
}

resource "aws_ecs_cluster" "cadt" {
    name = "create-a-derived-table"
    setting {
        name = "containerInsights"
        value = "enabled"
    }
}

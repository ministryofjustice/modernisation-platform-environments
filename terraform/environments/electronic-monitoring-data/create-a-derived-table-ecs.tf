resource "aws_ecs_task_definition" "create_a_derived_table" {
  family = "create-a-derived-table"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu = 10
  memory = 512

  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/create-a-derived-table:hmpps_electronic_monitoring_data_tables-123"
      cpu       = 10
      memory    = 512
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
          name  = "ATHENA_OUTPUT_BUCKET"
          value = "s3://${module.s3-athena-bucket.bucket.id}/output/"
        },
        {
          name  = "SNS_TOPIC_ARN"
          value = aws_sns_topic.emds_alerts.arn
        },
        {
          name  = "GDPR_REPORT_BUCKET"
          value = module.s3-gdpr-audit-bucket.bucket.id
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
}

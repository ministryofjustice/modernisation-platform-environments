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

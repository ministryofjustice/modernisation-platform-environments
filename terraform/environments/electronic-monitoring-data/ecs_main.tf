module "dagster_test" {
    source = "github.com/datarootsio/terraform-aws-ecs-dagster"

    resource_prefix = "test-dlt"
    resource_suffix = "env"

    vpc             = data.aws_vpc.shared.id
    public_subnet_ids  = [
      data.aws_subnet_ids.public_subnets_a.id,
      data.aws_subnet_ids.public_subnets_b.id,
      data.aws_subnet_ids.public_subnets_a.id
      ]

    rds_password = data.aws_secretsmanager_random_password.test.random_password
}

data "aws_secretsmanager_random_password" "test" {
  password_length = 50
  exclude_numbers = true
}
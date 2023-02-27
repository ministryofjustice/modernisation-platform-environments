#tfsec:ignore:aws-ec2-no-public-egress-sgr
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
module "ecs-new" {
  source = "github.com/ministryofjustice/terraform-ecs//cluster?ref=4f18199b40db858581c0e21af018e1cf8575d0f3"

  environment = local.environment
  name        = format("%s-new", local.application_name)

  tags = local.tags
}

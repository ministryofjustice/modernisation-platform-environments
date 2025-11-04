module "ears_sars_ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster"
  name        = "ear-sars-ecs-cluster"
  tags = merge(
    local.tags
  )
}

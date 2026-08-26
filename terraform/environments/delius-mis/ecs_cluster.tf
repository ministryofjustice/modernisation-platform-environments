# module "ecs" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"

#   environment = local.environment
#   namespace   = "mis"
#   name        = "cluster"

#   tags = local.tags
# }

# resource "aws_security_group" "cluster" {
#   name_prefix = "ecs-cluster-mis-${local.environment}-"
#   vpc_id      = data.aws_vpc.shared.id
#   lifecycle {
#     create_before_destroy = true
#   }
# }
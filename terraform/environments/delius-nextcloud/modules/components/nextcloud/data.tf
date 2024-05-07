# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# data "aws_subnet" "private_subnets_a" {
#   vpc_id = var.vpc_id
#   tags = {
#     "Name" = "${var.mp_subnet_prefix}-general-private-${data.aws_region.current.name}a"
#   }
# }

# data "aws_subnet" "private_subnets_b" {
#   vpc_id = var.vpc_id
#   tags = {
#     "Name" = "${var.mp_subnet_prefix}-general-private-${data.aws_region.current.name}b"
#   }
# }

# data "aws_subnet" "private_subnets_c" {
#   vpc_id = var.vpc_id
#   tags = {
#     "Name" = "${var.mp_subnet_prefix}-general-private-${data.aws_region.current.name}c"
#   }
# }

# data "aws_ssm_parameter" "bind_password" {
#   name = "/${var.namespace}-${var.environment}/LDAP_BIND_PASSWORD"
# }

# data "aws_ssm_parameter" "seed_uri" {
#   name = "/${var.namespace}-${var.environment}/LDAP_SEED_URI"
# }

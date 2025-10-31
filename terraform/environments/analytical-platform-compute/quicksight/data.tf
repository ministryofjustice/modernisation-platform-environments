# data "aws_availability_zones" "available" {}

# data "aws_iam_session_context" "current" {
#   arn = data.aws_caller_identity.current.arn
# }

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso-readonly
}

# Shared VPC and Subnets
data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnets" "shared_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*"
  }
}

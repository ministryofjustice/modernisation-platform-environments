##
# Create route 53 hosted zone to host records for resources
##
resource "aws_route53_zone" "private_internal_zone" {
  name = format("%s.internal", local.application_name)

  vpc {
    vpc_id = data.aws_vpc.shared.id
  }
}

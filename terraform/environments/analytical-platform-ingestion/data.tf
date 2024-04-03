data "aws_availability_zones" "available" {}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"

  depends_on = [module.vpc_endpoints]
}

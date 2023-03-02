#### This file can be used to store data specific to the member account ####

data "aws_vpc_endpoint" "s3" {
  provider     = aws.core-vpc
  vpc_id       = data.aws_vpc.shared.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.s3"
  }
}

data "aws_iam_policy" "wepi_iam_glue_policy_list" {
  for_each = toset(local.glue_iam_policy_list)
  name     = each.value
}

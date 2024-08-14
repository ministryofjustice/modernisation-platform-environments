data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

data "aws_prefix_list" "s3" {
  prefix_list_id = data.aws_ec2_managed_prefix_list.s3.id
}
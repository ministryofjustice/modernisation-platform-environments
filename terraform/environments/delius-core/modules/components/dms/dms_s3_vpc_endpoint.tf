# For AWS DMS version 3.4.7 and higher, DMS must access the source bucket through a VPC endpoint or a public route.
# Ref: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Target.S3.html#CHAP_Target.S3.Prerequisites
data "aws_route_tables" "all_route_tables" {
  filter {
    name   = "vpc-id"
    values = [var.account_info.vpc_id]
  }
}

resource "aws_vpc_endpoint" "s3_bucket_dms_destination" {
  vpc_id            = var.account_info.vpc_id
  service_name      = "com.amazonaws.${var.account_info.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.all_route_tables.ids
}
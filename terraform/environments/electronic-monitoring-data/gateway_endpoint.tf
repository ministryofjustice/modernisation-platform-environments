
resource "aws_vpc_endpoint" "gtw_ep_s3" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.s3"
    route_table_ids = ["rtb-065e8c1f6a34c126a", "rtb-0a92da52c0aefb033"]

    tags = {
        Name = "S3_Gateway_Endpoint"
    }
}

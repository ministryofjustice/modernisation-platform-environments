resource "aws_eip" "transfer_server" {
  count = length(data.aws_availability_zones.available.names)

  domain = "vpc"
}

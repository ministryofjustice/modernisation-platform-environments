# TODO: make this more elegant, use az count
resource "aws_eip" "transfer_server" {
  count = 3

  domain = "vpc"
}

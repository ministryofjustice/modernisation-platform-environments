/*
data "aws_network_acls" "public_acl" {
  vpc_id = data.aws_vpc.shared.id

  filter {
    name   = "association.subnet-id"
    values = [data.aws_subnet.public_subnets_a.id]
  }
}


resource "aws_network_acl_rule" "allow_http" {
  network_acl_id = tolist(data.aws_network_acls.public_acl.ids)[0]
  rule_number    = 230
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}
*/

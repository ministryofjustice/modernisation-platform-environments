
resource "aws_security_group" "internal_idm_sg" {
  name        = "${local.application_name}-internal-clb-security-group"
  description = "${local.application_name} internal clb security group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "internal_inbound" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = local.laa_mp_dev_cidr
  from_port         = 1389
  ip_protocol       = "tcp"
  to_port           = 1389
}


resource "aws_vpc_security_group_ingress_rule" "internal_inbound1" {
  security_group_id = aws_security_group.internal_idm_sg.id
  cidr_ipv4         = local.laa_mp_dev_cidr
  from_port         = 1636
  ip_protocol       = "tcp"
  to_port           = 1636
}
resource "aws_elb" "idm_lb" {
name                       = "${local.application_name}-internal-lb"
internal                   = true
instances                  = [aws_instance.idm_instance_1.id, aws_instance.idm_instance_2.id]
listener {
    instance_port     = 1389
    instance_protocol = "TCP"
    lb_port           = 1389
    lb_protocol       = "TCP"
  }


listener {
    instance_port     = 1636
    instance_protocol = "TCP"
    lb_port           = 1636
    lb_protocol       = "TCP"
  }


    health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 3
    target              = "TCP:1389/"
    interval            = 15
  }

}
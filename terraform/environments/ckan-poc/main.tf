resource "aws_security_group" "ckan_sg" {
  name = "ckan-sg"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_instance" "ckan_instance" {
  ami = "ami-f976839e"  
  instance_type = "t2.medium"
  security_groups = [aws_security_group.ckan_sg.id]
  tags = {
    Name = "ckan-instance"
  }

   user_data = data.template_file.ckan.rendered
}

data "template_file" "ckan" {
  template = file("ckan.sh")
}

resource "aws_elb" "ckan_lb" {
  name               = "ckan-lb"
  security_groups    = [ aws_security_group.ckan_sg.id ]
  subnets            = [ "subnet-0bc9984135d61ef53"]
  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5000/"
    interval            = 30
  }

  instances = [ aws_instance.ckan.id ]
}

output "ckan_lb_dns_name" {
  value = aws_elb.ckan_lb.dns_name
}



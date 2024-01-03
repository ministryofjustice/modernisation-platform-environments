resource "aws_instance" "cymulate-attack" {
    ami = "ami-0a398a6b09d71fecc" # May need to be changed for cymulate
    instance_type = "t3.small"
    subnet_id  = data.aws_subnet.private_subnets_a.id
    vpc_security_group_ids = [aws_security_group.cymulate-sg-attack-open.id]


    tags = {
        Name = "cymulate-attack-instance"
    }

    root_block_device {
      encrypted = true
    }
}

resource "aws_security_group" "cymulate-sg-attack-open" {
  name        = "cymulate-sg-attack-open"
  description = "cymulate attack open security group"
  vpc_id      = data.aws_vpc.shared.id

   tags = {
        Name = "cymulate-sg-attack-open"
    }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "cymulate-target-open" {
    ami = "ami-0a398a6b09d71fecc"
    instance_type = "t3.nano"
    subnet_id  = data.aws_subnet.private_subnets_a.id
    vpc_security_group_ids = [aws_security_group.cymulate-sg-open.id]


    tags = {
        Name = "cymulate-target-open"
    }

    root_block_device {
      encrypted = true
    }
}

resource "aws_security_group" "cymulate-sg-open" {
  name        = "cymulate-sg-open"
  description = "cymulate open security group"
  vpc_id      = data.aws_vpc.shared.id

   tags = {
        Name = "cymulate-sg-open"
    }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "cymulate-target-closed" {
    ami = "ami-0a398a6b09d71fecc"
    instance_type = "t3.nano"
    subnet_id  = data.aws_subnet.private_subnets_b.id
    vpc_security_group_ids = [aws_security_group.cymulate-sg-closed.id]


    tags = {
        Name = "cymulate-target-closed"
    }

    root_block_device {
      encrypted = true
    }
}

resource "aws_security_group" "cymulate-sg-closed" {
  name        = "cymulate-sg-closed"
  description = "cymulate closed security group"
  vpc_id      = data.aws_vpc.shared.id

   tags = {
        Name = "cymulate-sg-closed"
    }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
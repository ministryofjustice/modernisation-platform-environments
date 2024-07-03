resource "aws_instance" "dagster_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "DagsterServer"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              curl -sSL https://get.docker.com/ | sh
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              mkdir /opt/dagster
              cd /opt/dagster
              cat <<EOT >> docker-compose.yml
              version: '3.8'
              services:
                dagster:
                  image: dagster/dagster:latest
                  ports:
                    - "3000:3000"
              EOT
              docker-compose up -d
              EOF

  # Security group to allow SSH and HTTP access
  vpc_security_group_ids = [aws_security_group.dagster_sg.id]
}

resource "aws_security_group" "dagster_sg" {
  name_prefix = "dagster-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_dynamodb_table" "dagster_state" {
  name           = "dagster-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}
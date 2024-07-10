resource "aws_ecs_cluster" "dagster_cluster" {
  name = "dagster-cluster"
}

resource "aws_ecs_task_definition" "dagster_task" {
  family                   = "dagster-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.dagster_role.arn
  task_role_arn            = aws_iam_role.dagster_role.arn

  container_definitions = jsonencode([{
    name  = "dagster"
    image = "dagster/dagster:latest"
    essential = true

    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])
}

resource "aws_ecs_service" "dagster_service" {
  name            = "dagster-service"
  cluster         = aws_ecs_cluster.dagster_cluster.id
  task_definition = aws_ecs_task_definition.dagster_task.arn
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.shared-private
    security_groups  = [aws_security_group.dagster_sg.id]
    assign_public_ip = true
  }
}

resource "aws_security_group" "dagster_sg" {
  name        = "dagster_sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

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
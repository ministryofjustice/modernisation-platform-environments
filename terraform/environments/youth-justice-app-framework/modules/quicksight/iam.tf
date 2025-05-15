
# Create a role to allow quicksight to create a VPC connection
resource "aws_iam_role" "vpc_connection_role" {
  name               = "create-quicksight-vpc-connection"
  description        = "Rule to allow the Quicksite service to create a VPC connection."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "quicksight.amazonaws.com"
        }
      }
    ]
  })
}


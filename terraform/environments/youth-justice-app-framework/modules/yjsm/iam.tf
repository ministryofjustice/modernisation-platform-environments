resource "aws_iam_role" "yjsm_ec2_role" {
  name = "yjsm-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#todo add missing policies to this role
resource "aws_iam_role_policy_attachment" "yjsm_ec2_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
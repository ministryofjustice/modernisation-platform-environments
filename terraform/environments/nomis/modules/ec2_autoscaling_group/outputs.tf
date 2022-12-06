output "ec2_role_arn" {
  value = aws_iam_role.this.arn
  description = "ARN of the EC2 role created for the instances"
}

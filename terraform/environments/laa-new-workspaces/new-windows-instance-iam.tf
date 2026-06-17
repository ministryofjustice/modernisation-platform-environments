##############################################
### IAM Role for EC2 User Creation Instance
##############################################

resource "aws_iam_role" "user_creation_ec2_role" {

  name = "${local.application_name}-${local.environment}-user-creation-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-role" }
  )
}

resource "aws_iam_role_policy_attachment" "user_creation_ec2_ssm_managed" {

  role       = aws_iam_role.user_creation_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "user_creation_ec2_directory_service" {

  role       = aws_iam_role.user_creation_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

# Allow EC2 to read Secrets Manager secrets (for AD admin and service account passwords)
resource "aws_iam_role_policy" "user_creation_ec2_secrets_access" {

  name = "${local.application_name}-${local.environment}-user-creation-ec2-secrets"
  role = aws_iam_role.user_creation_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${local.application_data.accounts[local.environment].region}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/${local.environment}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "user_creation_ec2_profile" {

  name = "${local.application_name}-${local.environment}-user-creation-ec2-profile"
  role = aws_iam_role.user_creation_ec2_role.name

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-creation-ec2-profile" }
  )
}

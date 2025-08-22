# # Create an IAM role for the SFTP server
# resource "aws_iam_role" "sftp_role" {
#   name = "sftp-server-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "transfer.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Attach an IAM policy to the role for S3 access
# resource "aws_iam_role_policy" "sftp_policy" {
#   name = "sftp-s3-policy"
#   role = aws_iam_role.sftp_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "s3:ListBucket",
#           "s3:GetBucketLocation"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:s3:::${aws_s3_bucket.CAFM.bucket}"
#       },
#       {
#         Action = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:DeleteObjectVersion",
#           "s3:DeleteObject",
#           "s3:GetObjectVersion"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:s3:::${aws_s3_bucket.CAFM.bucket}/*"
#       }
#     ]
#   })
# }

# # Create the AWS Transfer Family SFTP server
# resource "aws_transfer_server" "sftp_server" {
#   identity_provider_type = "SERVICE_MANAGED"
#   endpoint_type = "VPC"

#   endpoint_details {
#     vpc_id             = module.vpc.vpc_id
#     subnet_ids         = module.vpc.private_subnets
#     security_group_ids = [aws_security_group.sftp_sg.id] # ✅ Attached here
#   }

#   protocols            = ["SFTP"]
#   security_policy_name = "TransferSecurityPolicy-2024-01"

#   tags = {
#     Name = "CAFM SFTP Server"
#   }
# }

# resource "aws_security_group" "sftp_sg" {
#   name        = "sftp-access"
#   description = "Security group for SFTP servers"
#   vpc_id      = "vpc-0b2907e67278ff255"

#   ingress {
#     description = "Only allow specific IPs"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["192.168.0.58/32",
#                    "94.195.119.194/32",
#                    "100.64.11.172/32"] # ✅ Only allow specific IPs
#     # cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "Allow all protocols to internal VPC range"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["10.0.0.0/8"]
#   }
# }


# # Create an SFTP user
# resource "aws_transfer_user" "sftp_user" {
#   server_id = aws_transfer_server.sftp_server.id
#   user_name = "sftp-user"
#   role      = aws_iam_role.sftp_role.arn
#   home_directory = "/${aws_s3_bucket.CAFM.bucket}"
# }


# # Adding SFTP ssh key
# resource "aws_transfer_ssh_key" "sftp-ssh-key" {
#   server_id = aws_transfer_server.sftp_server.id
#   user_name = aws_transfer_user.sftp_user.user_name
#   body = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaa4nS966z8WHgWZ0n2pDr+0/BNf06mTW4CdD6RJ1qIDIVVv55P4BN6dBSJVqDfkuOg0urG06LsE4FiRvYGViN4/fHc5mU0Jw0r6Gzu+g+yC7zLpV4LIhjHLxgEv86GzxIF3WjKDalbW0SrNyxoxJD6IKxr/IKLMAwsuVNSIXA18IZZwhdfvrT36YOBW+3+mSAblnOZkZh4ltpA7ATa7GSnQPFnoBmCT//wA8t/7aZ+OmN6ytERMiBpjI8DjFuUBlCHPKeSBsK2WGuXiNLrRocCqkAO3WpX5kmC8x3SXQOsjsuWRTloOycBFRdzNCL7RKIdS3cqyrkGpdJr4H7t0O/lYenVews5Plgau+H4/nnBIjIXmdLq8He6G0r/nxcIeTyTOpYwQ0pw+WzNQQJPeWmGnzOjEaiPJbZ/GHwI6j67KzIVcmYYeyfJnrF14VEj+tJSlsn8Rl6+Bu/nTtYjVMlLZOwqH33HQrSUmiycukN4CWc69LYg1hezfbABkVKRFcRcfl4v0HzDJ2wqQS5NU2m8NQWL18zqi4hy5X+Hx4NyAIRCqX3+7YhEpfQrbYVvGjILGFSc4O0PwtW4jHmmjIresPfz7QXoXRlAe2aAQlWYGfBVP3y0xMNk0QGoEJHDjOgVCsmHvUtC62qfdadqhPNMY9pf3YQ10PBfkIq96LDAQ== jyotiranjan.nayak@MJ005734"
# }

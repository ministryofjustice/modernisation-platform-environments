######################################
### EC2 INSTANCE Userdata File
######################################
locals {
  userdata_new = replace(
    file("${path.module}/files/new-userdata.sh"),
    "$${dns_zone_name}",
    data.aws_route53_zone.external.name
  )
}

######################################
### EC2 INSTANCE
######################################
resource "aws_instance" "oas_app_instance_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  ami = local.application_data.accounts[local.environment].ec2amiid
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  vpc_security_group_ids      = [aws_security_group.ec2_sg[0].id]
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_new[0].id
  user_data_replace_on_change = true
  user_data                   = base64encode(local.userdata_new)

  root_block_device {
    delete_on_termination = false
    encrypted             = true # TODO Confirm if encrypted volumes can work for OAS, as it looks like in MP they must be encrypted
    volume_size           = 40
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Apps Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}

######################################
### EC2 IAM ROLE AND PROFILE
######################################
resource "aws_iam_instance_profile" "ec2_instance_profile_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_instance_role_new[0].name
}

resource "aws_iam_role" "ec2_instance_role_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name               = "${local.application_name}-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_attachment_new" {
  count      = contains(["test", "preproduction"], local.environment) ? 1 : 0
  role       = aws_iam_role.ec2_instance_role_new[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_instance_policy_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role_new[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001",
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      }
    ]
  })
}

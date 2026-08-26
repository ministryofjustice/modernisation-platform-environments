variable "my_ip" {
  type    = string
  default = "18.170.74.92/32"
}

# Kali Linux Instance
resource "aws_instance" "kali_linux" {
  ami                         = "ami-0f398bcc12f72f967" // aws-marketplace/kali-last-snapshot-amd64-2024.2.0-804fcc46-63fc-4eb6-85a1-50e66d6c7215
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnets.0
  vpc_security_group_ids      = [aws_security_group.kali_linux_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  ebs_optimized               = true

  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted   = true
    volume_size = 60
  }
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 5
    encrypted   = true
  }
  user_data = <<-EOF
              #!/bin/bash
              
              set -e
              exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

              # Update system packages
              echo "Updating and upgrading system packages..."
              apt-get update -y
              apt-get upgrade -y

              # Install necessary tools and Kali default tools
              echo "Installing wget, git, and kali-linux-default tools..."
              apt-get install -y wget git kali-linux-default

              # Check if 'kali' user exists
              if id "kali" &>/dev/null; then
                  echo "User 'kali' exists. Proceeding to create tooling directory..."
                  
                  # Create tooling directory and set ownership
                  mkdir -p /home/kali/tooling
                  chown -R kali:kali /home/kali
                  echo "Tooling directory created under /home/kali and ownership set."

                  # Clone the repository as 'kali' user
                  echo "Cloning gotestwaf repository into /home/kali/tooling..."
                  sudo -u kali git clone https://github.com/wallarm/gotestwaf.git /home/kali/tooling
                  echo "Repository cloned successfully."
              else
                  echo "User 'kali' does not exist. Exiting."
                  exit 1
              fi

              echo "User data script completed successfully."

              EOF

  tags = {
    Name = "Terraform-Kali-Linux"
  }
}


# Defect Dojo Instance
resource "aws_instance" "defect_dojo" {
  ami                         = "ami-0e8d228ad90af673b"
  associate_public_ip_address = true
  instance_type               = "t2.large"
  subnet_id                   = module.vpc.private_subnets.0
  vpc_security_group_ids      = [aws_security_group.defect_dojo_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  ebs_optimized               = true

  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    encrypted   = true
    volume_size = 60
  }
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 5
    encrypted   = true
  }
  user_data = <<-EOF
              #!/bin/bash
              # Update and install dependencies
              sudo apt-get update
              sudo apt-get upgrade
              cd /home
              sudo mkdir appsec
              cd appsec
              sudo git clone https://github.com/DefectDojo/django-DefectDojo.git
              cd django-DefectDojo
              sudo apt install docker.io -y
              sudo apt install docker-compose -y
              sudo docker-compose up -d
              EOF

  tags = {
    Name = "Defect-Dojo"
  }
}


# Security Group for Kali instance
# trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "kali_linux_sg" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all traffic outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Defect Dojo instance
# trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "defect_dojo_sg" {
  lifecycle {
    create_before_destroy = true
  }
  name        = "allow_tcp"
  description = "Allow TCP inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow TCP/8080 from my IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Allow TCP/443 from my IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Allow TCP/8443 from my IP"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # New rules for Local VPN (10.0.0.0/16)

  ingress {
    description = "Allow TCP/8080 from VPN subnet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow TCP/8080 from VPN subnet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    description = "Allow TCP/8080 from VPN subnet"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    description = "Allow all traffic outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM role for EC2 instances
resource "aws_iam_role" "ssm_role" {
  name = "SSMInstanceProfile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_role.name
}

# Attach an additional policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "SSMInstanceS3AccessPolicy"
  description = "Policy to allow EC2 to access the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          module.s3-bucket.bucket.arn,
          "${module.s3-bucket.bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the existing SSM role
resource "aws_iam_role_policy_attachment" "ssm_s3_access_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Create the instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# Create S3 bucket
module "s3-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=4e17731f72ef24b804207f55b182f49057e73ec9" #v8.1.0

  bucket_prefix      = "panda-cyber-bucket"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "s3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      module.s3-bucket.bucket.arn,
      "${module.s3-bucket.bucket.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ssm_role.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3-bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}





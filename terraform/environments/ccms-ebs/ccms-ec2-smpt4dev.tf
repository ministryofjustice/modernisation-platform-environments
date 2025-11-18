#Create AWS IAM Role Profile for EC2
resource "aws_iam_role" "ec2_ssm_role" {
  name = "smtp4dev-role"

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
}

# Attach AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for SMTP4dev EC2 to use the role
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "smtp4dev-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# Build smtp4dev EC2 
resource "aws_instance" "smtp4dev_mock_server" {
  instance_type          = "t3.medium"
  ami                    = "ami-07eb36e50da2fcccd"
  vpc_security_group_ids = [aws_security_group.smtp4dev_mock_server_sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  #subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

 #place holder for user data changes
  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/ec2_user_data_smpt4dev.sh", {
    environment               = "${local.environment}"
  }))

#   metadata_options {
#     http_endpoint = "enabled"
#     http_tokens   = "required"
#   }

  # Increase the volume size of the root volume
#   root_block_device {
#     volume_type = "gp3"
#     volume_size = 50
#     iops        = 3000
#     encrypted   = true
#     kms_key_id  = data.aws_kms_key.ebs_shared.key_id
#     tags = merge(local.tags,
#       { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_, "root")) },
#       { device-name = "/dev/sda1" }
#     )
#   }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-mailrelay", local.application_name, local.environment)) },
    { instance-scheduling = "skip-auto-start" },
    { backup = "true" }
  )

#   depends_on = [aws_security_group.ec2_sg_mailrelay]
}


# Create Route53 record for SMTP4Dev EC2 instance
# resource "aws_route53_record" "route53_record_smtp4dev" {
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.internal.zone_id
#   name     = "smtp4dev.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal"
#   type     = "A"
#   ttl      = "300"
#   records  = [aws_instance.smtp4dev_mock_server.private_ip]
# }

# output "route53_record_smtp4dev" {
#   description = "SMTP4Dev Route53 record"
#   value       = aws_route53_record.route53_record_smtp4dev.fqdn
# }
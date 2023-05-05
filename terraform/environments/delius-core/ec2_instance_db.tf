##
# Terraform to deploy an instance to test out a base Oracle AMI
##

# Pre-req - security group
resource "aws_security_group" "base_ami_test_instance_sg" {
  name        = "base-ami-test-instance-sg"
  description = "Controls access to base AMI instance"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
  )
}

# Pre-req - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "base_ami_test_instance_iam_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "base_ami_test_instance_iam_role" {
  name               = "base_ami_test_instance_iam_role"
  assume_role_policy = data.aws_iam_policy_document.base_ami_test_instance_iam_assume_policy.json
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "base_ami_test_instance_AmazonSSMMaagedInstanceCore" {
  role       = aws_iam_role.base_ami_test_instance_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "base_ami_test_instance_profile" {
  name = "base_ami_test_instance_iam_role"
  role = aws_iam_role.base_ami_test_instance_iam_role.name
}

resource "aws_instance" "base_ami_test_instance" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = "t2.micro"
  ami                         = "ami-04074b470fd99b34e"
  vpc_security_group_ids      = [aws_security_group.base_ami_test_instance_sg.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.base_ami_test_instance_profile.name
  associate_public_ip_address = false
  monitoring                  = false
  ebs_optimized               = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
  )
}


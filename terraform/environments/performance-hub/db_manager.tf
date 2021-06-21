resource "aws_instance" "db_mgmt_server" {
  ami                         = "ami-09b00616b12b077f8"
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.db_mgmt_profile.name
  instance_type               = "t3.large"
  key_name                    = var.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  user_data                   = data.template_cloudinit_config.cloudinit-db-mgmt.rendered
  vpc_security_group_ids      = [aws_security_group.db_mgmt_server_security_group.id, ]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = aws_kms_key.ebs.id
    volume_size           = 150
    volume_type           = "gp3"
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device, # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }
}

data "template_file" "db_mgmt_server_script" {
  template = file("./templates/db_mgmt_server.txt")
}

data "template_cloudinit_config" "cloudinit-db-mgmt" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.db_mgmt_server_script.rendered
  }
}

data "aws_iam_policy_document" "db_mgmt_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "db_mgmt_role" {
  name               = "${local.application_name}-role"
  assume_role_policy = data.aws_iam_policy_document.db_mgmt_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "db-mgmt-attach-policy" {
  role       = aws_iam_role.db_mgmt_role.name
  policy_arn = aws_iam_policy.db_mgmt_policy.arn
}

resource "aws_iam_instance_profile" "db_mgmt_profile" {
  name = "${local.application_name}-db-mgmt-profile"
  role = aws_iam_role.db_mgmt_role.name
}

# ebs ec2 policy
resource "aws_iam_policy" "db_mgmt_policy" {
  name        = "${local.application_name}-db_mgmt-ec2-policy"
  description = "${local.application_name} ec2-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetEncryptionConfiguration"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": "arn:aws:kms:eu-west-2:322518575883:key/c1b9e987-29e2-458f-b5bd-2e9c2b57f049"
      }
    ]
}
EOF
}

# EC2 Security Group
resource "aws_security_group" "db_mgmt_server_security_group" {
  name_prefix = "${local.application_name}-db-mgmt-server-sg"
  description = "controls access to the db mgmt server"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol  = "tcp"
    from_port = 3389
    to_port   = 3389
    #cidr_blocks = [ "${module.bastion_linux.bastion_private_ip}/32" ]
    cidr_blocks = [ "10.236.0.21/32" ]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = local.tags
}

#------------------------------------------------------------------------------
# KMS setup for S3
#------------------------------------------------------------------------------

resource "aws_kms_key" "ebs" {
  description         = "Encryption key for EBS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ebs-kms.json

  tags = merge(
    local.tags,
    {
      Name = "ebs-kms"
    },
  )
}

resource "aws_kms_alias" "ebs-kms-alias" {
  name          = "alias/ebs"
  target_key_id = aws_kms_key.ebs.arn
}

data "aws_iam_policy_document" "ebs-kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

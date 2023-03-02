resource "aws_instance" "db_mgmt_server" {
  ami                         = "ami-03e88be9ecff64781"
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.db_mgmt_profile.name
  instance_type               = "t3.large"
  #  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring             = true
  subnet_id              = data.aws_subnet.private_subnets_a.id
  user_data              = data.template_cloudinit_config.cloudinit-db-mgmt.rendered
  vpc_security_group_ids = [aws_security_group.db_mgmt_server_security_group.id, ]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

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
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-mgmt-server"
    }
  )
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
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db_mgmt_role"
    }
  )
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
#tfsec:ignore:AWS099
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
#tfsec:ignore:AWS009 #tfsec:ignore:no-public-egress-sgr
resource "aws_security_group" "db_mgmt_server_security_group" {
  name_prefix = "${local.application_name}-db-mgmt-server-sg"
  description = "controls access to the db mgmt server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-mgmt-server-sg"
    }
  )
}

resource "aws_security_group_rule" "db_ingress_tcp_3389" {
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_mgmt_server_security_group.id
  description              = "Open the RDP port"
  from_port                = 3389
  to_port                  = 3389
  source_security_group_id = module.bastion_linux.bastion_security_group
  type                     = "ingress"
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "db_egress_any" {
  protocol          = -1
  security_group_id = aws_security_group.db_mgmt_server_security_group.id
  description       = "All outbound ports open"
  from_port         = -1
  to_port           = -1
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
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
      Name = "${local.application_name}-ebs-kms"
    }
  )
}

resource "aws_kms_alias" "ebs-kms-alias" {
  name          = "alias/ebs"
  target_key_id = aws_kms_key.ebs.arn
}

data "aws_iam_policy_document" "ebs-kms" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
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

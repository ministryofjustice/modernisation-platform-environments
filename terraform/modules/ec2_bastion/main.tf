# get shared subnet-set vpc object
data "aws_vpc" "shared_vpc" {
  # provider = aws.share-host
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnets" "local_account" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_vpc.id]
  }
}

data "aws_subnet" "local_account" {
  for_each = toset(data.aws_subnets.local_account.ids)
  id       = each.value
}

# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-private-${var.region}a"
  }
}

# get core_vpc account protected subnets security group
data "aws_security_group" "core_vpc_protected" {
  provider = aws.share-host

  tags = {
    Name = "${var.business_unit}-${var.environment}-int-endpoint"
  }
}

# get core_vpc account S3 endpoint
data "aws_vpc_endpoint" "s3" {
  provider     = aws.share-host
  vpc_id       = data.aws_vpc.shared_vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  tags = {
    Name = "${var.business_unit}-${var.environment}-com.amazonaws.${var.region}.s3"
  }

}

# S3
resource "aws_kms_key" "bastion_s3" {
  enable_key_rotation = true

  tags = merge(
    var.tags_common,
    {
      Name = "bastion_s3"
    },
  )
}

resource "aws_kms_alias" "bastion_s3_alias" {
  name          = "alias/s3-${var.bucket_name}_key"
  target_key_id = aws_kms_key.bastion_s3.arn
}

resource "random_string" "random6" {
  length  = 6
  special = false
}

module "s3-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    # Since replication_enabled is false, the below provider is not being used.
    # Therefore, just to get around the requirement, we pass the aws.share-tenant.
    # If replication was enabled, a different provider would be needed.
    aws.bucket-replication = aws.share-tenant
  }
  bucket_name         = "${var.bucket_name}-${var.tags_prefix}-${lower(random_string.random6.result)}"
  replication_enabled = false
  force_destroy       = true

  lifecycle_rule = [
    {
      id      = "log"
      enabled = var.log_auto_clean
      prefix  = "logs/"

      tags = {
        rule      = "log"
        autoclean = var.log_auto_clean
      }

      transition = [
        {
          days          = var.log_standard_ia_days
          storage_class = "STANDARD_IA"
          }, {
          days          = var.log_glacier_days
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = var.log_expiry_days
      }

      noncurrent_version_transition = [
        {
          days          = var.log_standard_ia_days
          storage_class = "STANDARD_IA"
          }, {
          days          = var.log_glacier_days
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = var.log_expiry_days
      }
    }
  ]

  tags = merge(
    var.tags_common,
    {
      Name = "bastion-linux"
    },
  )
}

resource "aws_s3_object" "bucket_public_keys_readme" {
  bucket = module.s3-bucket.bucket.id

  key        = "public-keys/README.txt"
  content    = "Drop here the ssh public keys of the instances you want to control"
  kms_key_id = aws_kms_key.bastion_s3.arn

  tags = merge(
    var.tags_common,
    {
      Name = "bastion-${var.app_name}-README.txt"
    }
  )

}

resource "aws_s3_object" "user_public_keys" {
  for_each = var.public_key_data

  bucket     = module.s3-bucket.bucket.id
  key        = "public-keys/${each.key}.pub"
  content    = each.value
  kms_key_id = aws_kms_key.bastion_s3.arn

  tags = merge(
    var.tags_common,
    {
      Name = "bastion-${var.app_name}-${each.key}-publickey"
    }
  )

}

# Security Groups
resource "aws_security_group" "bastion_linux" {
  description = "Configure bastion access - ingress should be only from Systems Session Manager (SSM)"
  name        = "bastion-linux-${var.app_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  tags = merge(
    var.tags_common,
    {
      Name = "bastion-linux-${var.app_name}"
    }
  )
}

resource "aws_security_group_rule" "basion_linux_egress_1" {
  security_group_id = aws_security_group.bastion_linux.id

  description = "bastion_linux_to_local_subnet_CIDRs"
  type        = "egress"
  from_port   = "0"
  to_port     = "65535"
  protocol    = "TCP"
  cidr_blocks = [for s in data.aws_subnet.local_account : s.cidr_block]
}

resource "aws_security_group_rule" "basion_linux_egress_2" {
  security_group_id = aws_security_group.bastion_linux.id

  description              = "bastion_linux_egress_to_inteface_endpoints"
  type                     = "egress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "TCP"
  source_security_group_id = data.aws_security_group.core_vpc_protected.id
}

resource "aws_security_group_rule" "bastion_linux_egress_3" {
  security_group_id = aws_security_group.bastion_linux.id

  description     = "bastion_linux_egress_to_s3_endpoint"
  type            = "egress"
  from_port       = "443"
  to_port         = "443"
  protocol        = "TCP"
  prefix_list_ids = [data.aws_vpc_endpoint.s3.prefix_list_id]
}


# IAM
data "aws_iam_policy_document" "bastion_assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion_role" {
  name               = "bastion_linux_ec2_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_policy_document.json

  tags = merge(
    var.tags_common,
    {
      Name = "bastion_linux_ec2_role"
    },
  )
}

#wildcards permissible for access to log bucket objects
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "bastion_policy_document" {

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject"
    ]
    resources = ["${module.s3-bucket.bucket.arn}/logs/*"]
  }

  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = ["${module.s3-bucket.bucket.arn}/public-keys/*"]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [module.s3-bucket.bucket.arn]

    condition {
      test = "ForAnyValue:StringEquals"
      values = [
        "public-keys/",
        "logs/"
      ]
      variable = "s3:prefix"
    }
  }

  statement {
    actions = [

      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.bastion_s3.arn]
  }
}

resource "aws_iam_policy" "bastion_policy" {
  name   = "bastion"
  policy = data.aws_iam_policy_document.bastion_policy_document.json
}

resource "aws_iam_role_policy_attachment" "bastion_s3" {
  policy_arn = aws_iam_policy.bastion_policy.arn
  role       = aws_iam_role.bastion_role.name
}

resource "aws_iam_role_policy_attachment" "bastion_managed" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion_role.name
}

#wildcards permissible read access to specific buckets
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "bastion_ssm_s3_policy_document" {

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::aws-ssm-${var.region}/*",
      "arn:aws:s3:::aws-windows-downloads-${var.region}/*",
      "arn:aws:s3:::amazon-ssm-${var.region}/*",
      "arn:aws:s3:::amazon-ssm-packages-${var.region}/*",
      "arn:aws:s3:::${var.region}-birdwatcher-prod/*",
      "arn:aws:s3:::aws-ssm-distributor-file-${var.region}/*",
      "arn:aws:s3:::aws-ssm-document-attachments-${var.region}/*",
      "arn:aws:s3:::patch-baseline-snapshot-${var.region}/*"
    ]
  }
}

resource "aws_iam_policy" "bastion_ssm_s3_policy" {
  name   = "bastion_ssm_s3"
  policy = data.aws_iam_policy_document.bastion_ssm_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "bastion_host_ssm_s3" {
  policy_arn = aws_iam_policy.bastion_ssm_s3_policy.arn
  role       = aws_iam_role.bastion_role.name
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-ec2-profile"
  role = aws_iam_role.bastion_role.name
  path = "/"
}

## Bastion

data "aws_ami" "linux_2_image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "bastion_linux_template" {
  name = "bastion_linux_template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
      encrypted   = true
    }
  }

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion_profile.id
  }

  image_id                             = data.aws_ami.linux_2_image.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t3.micro"

  metadata_options {
    http_endpoint               = "enabled" # defaults to enabled but is required if http_tokens is specified
    http_put_response_hop_limit = 1         # default is 1, value values are 1 through 64
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    device_index                = 0
    security_groups             = [aws_security_group.bastion_linux.id]
    subnet_id                   = data.aws_subnet.private_az_a.id
    delete_on_termination       = true
  }

  placement {
    availability_zone = "${var.region}a"
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags_common,
      {
        Name = "bastion_linux"
      }
    )
  }

  user_data = base64encode(
    templatefile(
      "${path.module}/templates/user_data.sh.tftpl",
      {
        aws_region              = var.region
        bucket_name             = module.s3-bucket.bucket.id
        extra_user_data_content = var.extra_user_data_content
        allow_ssh_commands      = var.allow_ssh_commands
      }
    )
  )
}

resource "aws_autoscaling_group" "bastion_linux_daily" {
  launch_template {
    id      = aws_launch_template.bastion_linux_template.id
    version = "$Latest"
  }
  availability_zones        = ["${var.region}a"]
  name                      = "bastion_linux_daily"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "bastion_linux"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags_common

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "bastion_linux_scale_down" {
  scheduled_action_name  = "bastion_linux_scale_down"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 20 * * *" # 20.00 UTC time or 21.00 London time
  autoscaling_group_name = aws_autoscaling_group.bastion_linux_daily.name
}

resource "aws_autoscaling_schedule" "bastion_linux_scale_up" {
  scheduled_action_name  = "bastion_linux_scale_up"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 5 * * *" # 5.00 UTC time or 6.00 London time
  autoscaling_group_name = aws_autoscaling_group.bastion_linux_daily.name
}

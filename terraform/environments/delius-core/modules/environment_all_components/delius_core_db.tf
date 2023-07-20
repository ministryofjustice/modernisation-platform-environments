##
# Some work started here to flesh out use of the mod platform-curated modernisation-platform-terraform-ec2-instance module
# Current commented out but planned to pick this back up very soon to move away from our
#   native ec2 instance (engineered as we were prototyping our delius core db AMIs/test instance)
#   to a module-based ec2 instance
##
 module "ec2_instance" {
    source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v2.0.0"

   providers = {
    #aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }
#
#  for_each = try(local.ec2_test.ec2_test_instances, {})
#
#  name = each.key

    name             = local.db_config.name
    business_unit    = var.account_info.business_unit # hmpps
    application_name = var.account_info.application_name # delius-core
    region           = var.account_info.region # eu-west-2
    environment      = var.account_info.environment # equates to one of the 4 MP environment names, e.g. development
    subnet_id        = data.aws_subnet.private_subnets_a.id

    ami_name                      = var.db_config.ami_name # delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z
    ami_owner                     = local.environment_management.account_ids["core-shared-services-production"] # 
    instance                      = local.db_config.instance
                   
    user_data_raw = base64encode(
        templatefile(
            "${path.module}/templates/userdata.sh.tftpl",
            {
                branch               = "main"
                ansible_repo         = "modernisation-platform-configuration-management"
                ansible_repo_basedir = "ansible"
                ansible_args         = "oracle_19c_install"
            }
        )
    )

    ebs_volume_config             = local.db_config.ebs_volume_config
    ebs_volumes                   = local.db_config.ebs_volumes
    route53_records               = local.db_config.route53_records

    iam_resource_names_prefix = "ec2-test-instance"
    instance_profile_policies = [
        aws_iam_policy.base_ami_test_instance_iam_assume_policy.arn,
        aws_iam_policy.business_unit_kms_key_access.arn,
        aws_iam_policy.core_shared_services_bucket_access.arn,
        aws_iam_policy.ec2_access_for_ansible.arn
    ]
    tags = merge(local.tags, {
    Name = lower(format("%s-%s", local.application_name, local.environment))
  })

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

resource "aws_iam_policy" "base_ami_test_instance_iam_assume_policy" {
  name        = "base_ami_test_instance_iam_assume_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.base_ami_test_instance_iam_assume_policy.json
  tags = merge(
    local.tags,
    {
      Name = "base_ami_test_instance_iam_assume_policy"
    },
  )
}

#resource "aws_iam_role" "base_ami_test_instance_iam_role" {
#  name               = "base_ami_test_instance_iam_role"
#  assume_role_policy = data.aws_iam_policy_document.base_ami_test_instance_iam_assume_policy.json
#  tags = merge(local.tags,
#    { Name = lower(format("sg-%s-%s-base-ami-test-instance", local.application_name, local.environment)) }
#  )
#}

data "aws_iam_policy_document" "business_unit_kms_key_access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      data.aws_kms_key.general_shared.arn
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  name        = "business_unit_kms_key_access_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.business_unit_kms_key_access.json
  tags = merge(
    local.tags,
    {
      Name = "business_unit_kms_key_access_policy"
    },
  )
}

data "aws_iam_policy_document" "core_shared_services_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::mod-platform-image-artefact-bucket*/*",
      "arn:aws:s3:::mod-platform-image-artefact-bucket*"
    ]
  }
}

resource "aws_iam_policy" "core_shared_services_bucket_access" {
  name        = "core_shared_services_bucket_access_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.core_shared_services_bucket_access.json
  tags = merge(
    local.tags,
    {
      Name = "core_shared_services_bucket_access_policy"
    },
  )
}

data "aws_iam_policy_document" "ec2_access_for_ansible" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_access_for_ansible" {
  name        = "ec2_access_for_ansible"
  path        = "/"
  policy      = data.aws_iam_policy_document.ec2_access_for_ansible.json
  tags = merge(
    local.tags,
    {
      Name = "ec2_access_for_ansible_policy"
    },
  )
}

#resource "aws_iam_role_policy" "business_unit_kms_key_access" {
#  name   = "business_unit_kms_key_access"
#  role   = aws_iam_role.base_ami_test_instance_iam_role.name
#  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
#}
#
#resource "aws_iam_role_policy" "core_shared_services_bucket_access" {
#  name   = "core_shared_services_bucket_access"
#  role   = aws_iam_role.base_ami_test_instance_iam_role.name
#  policy = data.aws_iam_policy_document.core_shared_services_bucket_access.json
#}
#
#resource "aws_iam_role_policy" "ec2_access" {
#  name   = "ec2_access"
#  role   = aws_iam_role.base_ami_test_instance_iam_role.name
#  policy = data.aws_iam_policy_document.ec2_access_for_ansible.json
#}
#
#resource "aws_iam_role_policy_attachment" "base_ami_test_instance_amazonssmmanagedinstancecore" {
#  role       = aws_iam_role.base_ami_test_instance_iam_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#}
#
#resource "aws_iam_instance_profile" "base_ami_test_instance_profile" {
#  name = "base_ami_test_instance_iam_role"
#  role = aws_iam_role.base_ami_test_instance_iam_role.name
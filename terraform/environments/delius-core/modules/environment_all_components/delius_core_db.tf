##
# Some work started here to flesh out use of the mod platform-curated modernisation-platform-terraform-ec2-instance module
# Current commented out but planned to pick this back up very soon to move away from our
#   native ec2 instance (engineered as we were prototyping our delius core db AMIs/test instance)
#   to a module-based ec2 instance
##
module "ec2_instance" {
    source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v2.0.0"

    providers = {
       aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
    }
#
#  for_each = try(local.ec2_test.ec2_test_instances, {})
#
#  name = each.key

    name             = var.db_config.name
    business_unit    = var.account_info.business_unit # hmpps
    application_name = var.account_info.application_name # delius-core
    region           = var.account_info.region # eu-west-2
    environment      = var.account_info.mp_environment # equates to one of the 4 MP environment names, e.g. development
    subnet_id        = var.subnet_id

    ami_name            = var.db_config.ami_name # delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z
    ami_owner           = var.db_config.ami_owner # 
    instance            = var.db_config_instance
    user_data_raw       = var.db_config.user_data_raw
    ebs_volume_config   = var.db_config_ebs_volume_config
    ebs_volumes         = var.db_config_ebs_volumes
    route53_records     = var.db_config_route53_records

    instance_profile_policies = [
        aws_iam_policy.base_ami_test_instance_iam_assume_policy.arn,
        aws_iam_policy.business_unit_kms_key_access.arn,
        aws_iam_policy.core_shared_services_bucket_access.arn,
        aws_iam_policy.ec2_access_for_ansible.arn
    ]
    tags = var.db_config_tags
}
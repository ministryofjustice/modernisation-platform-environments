# module "ssm-auto-patching" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ssm-patching.git?ref=v4.0.0"
#   providers = {
#     aws.bucket-replication = aws
#   }
#   account_number   = local.environment_management.account_ids[terraform.workspace]
#   application_name = local.application_name
#   tags = merge(
#     local.tags,
#     {
#       Name = "ssm-patching"
#     },
#   )
# }


# resource "aws_ssm_patch_group" "oracle_db_patchgroup" {
#   baseline_id = module.ssm-auto-patching.baselines["oracle-linux-8-patch-baseline"].id
#   patch_group = "oracle_db_patchgroup"
# }

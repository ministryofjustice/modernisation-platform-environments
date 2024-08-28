module "actions_runner_cache_efs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.3"

  name          = "actions-runner-cache"
  encrypted     = true
  kms_key_arn   = module.actions_runner_cache_efs_kms.key_arn
  attach_policy = false

  enable_backup_policy = true

  mount_targets = {
    "private-subnets-0" = {
      subnet_id = module.vpc.private_subnets[0]
    }
    "private-subnets-1" = {
      subnet_id = module.vpc.private_subnets[1]
    }
    "private-subnets-2" = {
      subnet_id = module.vpc.private_subnets[2]
    }
  }

  security_group_vpc_id = module.vpc.vpc_id
  security_group_rules = {
    private-subnets = {
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }

  access_points = {
    cache = {
      name = "cache"
      posix_user = {
        gid = 10000
        uid = 10000
      }
      root_directory = {
        path = "/cache"
        creation_info = {
          owner_gid   = 10000
          owner_uid   = 10000
          permissions = "775"
        }
      }
    }
  }

  tags = local.tags
}

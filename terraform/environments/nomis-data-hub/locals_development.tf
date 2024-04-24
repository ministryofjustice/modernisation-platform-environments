locals {
  development_config = {
    baseline_efs = {
      dev_efs = {
        #access_points = {
        #  root = {
        #    posix_user = {
        #      gid            = 100
        #      uid            = 100
        #      secondary_gids = [200]
        #    }
        #    root_directory = {
        #      path = "/"
        #      creation_info = {
        #        owner_gid   = 100
        #        owner_uid   = 100
        #        permissions = 0777
        #      }
        #    }
        #  }
        #}
        #backup_policy_status = "DISABLED"
        file_system = {
          #availability_zone_name = "eu-west-2a"
          #lifecycle_policy = {
          #  transition_to_ia                    = "AFTER_30_DAYS"
          #  transition_to_primary_storage_class = "AFTER_1_ACCESS"
          #}
        }
        #mount_targets = [{
        #  subnet_name        = "private"
        #  availability_zones = ["eu-west-2a"]
        #  security_groups    = ["private"]
        #}]
        #policy = [{
        #  sid    = "test"
        #  effect = "Allow"
        #  actions = [
        #    "elasticfilesystem:ClientMount",
        #    "elasticfilesystem:ClientWrite",
        #  ]
        #  resources = ["*"]
        #  conditions = [{
        #    test     = "Bool"
        #    variable = "aws:SecureTransport"
        #    values   = ["true"]
        #  }]
        #}]
        #tags = {
        #  foo = "bar"
        #}
      }
    }
  }
}

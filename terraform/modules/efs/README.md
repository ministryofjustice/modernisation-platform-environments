# Elastic File System (EFS) Module

For use within a Modernisation Platform environment.
See https://github.com/ministryofjustice/modernisation-platform-configuration-management repo
for ansible code for mounting on linux server (filesystems role)

## Multi-AZ example

With elastic throughput mode and transition to IA/Archive configured.

```
module "efs1" {
  source = "../../modules/efs"

  access_points = {
    root = {
      posix_user = {
        gid = 10003
        uid = 10003
      }
      root_directory = {
        path = "/"
        creation_info = {
          owner_gid   = 10003
          owner_uid   = 10003
          permissions = "0777"
        }
      }
    }
  }
  file_system = {
    kms_key_id      = data.aws_kms_key.general_shared.arn
    throughput_mode = "elastic"
    lifecycle_policy = {
      transition_to_archive               = "AFTER_90_DAYS"
      transition_to_ia                    = "AFTER_30_DAYS"
      transition_to_primary_storage_class = "AFTER_1_ACCESS"
    }
  }
  mount_targets = {
    "private-eu-west-2a" = {
      subnet_id       = data.aws_subnet.private_subnets_a.id
      security_groups = [module.baseline.security_groups["private"].id]
    }
    "private-eu-west-2b" = {
      subnet_id       = data.aws_subnet.private_subnets_b.id
      security_groups = [module.baseline.security_groups["private"].id]
    }
    "private-eu-west-2c" = {
      subnet_id       = data.aws_subnet.private_subnets_c.id
      security_groups = [module.baseline.security_groups["private"].id]
    }
  }
  name = "efs1"
  tags = local.tags
}

output "efs1_dns_name" {
  description = "EFS DNS name"
  value = module.efs1.file_system.dns_name
}
```

## Single-AZ example

In default burst-mode but with example EFS policy and backup enabled

```
module "efs2" {
  source = "../../modules/efs"

  access_points = {
    root = {
      posix_user = {
        gid = 10003
        uid = 10003
      }
      root_directory = {
        path = "/"
        creation_info = {
          owner_gid   = 10003
          owner_uid   = 10003
          permissions = "0777"
        }
      }
    }
  }
  backup_policy_status = "ENABLED"
  file_system = {
    availability_zone_name = "eu-west-2a"
    kms_key_id      = data.aws_kms_key.general_shared.arn
    lifecycle_policy = {
      transition_to_ia = "AFTER_30_DAYS"
    }
  }
  mount_targets = {
    "private-eu-west-2a" = {
      subnet_id       = data.aws_subnet.private_subnets_a.id
      security_groups = [module.baseline.security_groups["private"].id]
    }
  }
  name = "efs2"
  policy = [{
    sid    = "test"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = ["*"]
    conditions = [{
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }]
  }]

  tags = local.tags
}

output "efs2_dns_name" {
  description = "EFS DNS name"
  value = module.efs2.file_system.dns_name
}
```

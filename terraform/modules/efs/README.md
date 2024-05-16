# Elastic File System (EFS) Module

Creates EFS file system and associated resources.

See <https://github.com/ministryofjustice/modernisation-platform-configuration-management> repo.
for ansible code for mounting on linux server (filesystems role).

EFS is expensive. Use Single-AZ solution for non-production environments to save cost.
Opt in or out of Modernisation Platform backup using `backup` tag.

## Security Groups

The module does not create security groups. NFS has no authentication
so be sure to limit access to only what needs it.

###  Example 1 - Same security group as EC2

Use the same security group as the EC2 mounting the EFS.
Just ensure there is an internal rule allowing internal traffic
like this:

```
resource "aws_security_group_rule" "all_from_self" {
  security_group_id = aws_security_group.ec2.id
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}
```

###  Example 2 - Separate security group

Create a separate security group and allow inbound traffic
only from the security groups that the EC2s belong to.

```
resource "aws_security_group" "efs" {
  name   = "efs"
  vpc_id = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "efs_ingress" {
  security_group_id        = aws_security_group.efs.id
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
}
```

## Multi-AZ example

This:
- creates multi-AZ solution with mount points in each AZ
- associates the mount point with a `aws_security_group.ec2` resource, see Security Groups - Example 1
- enables elastic throughput mode with transition to IA and archive

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
      security_groups = [aws_security_group.ec2.id]
    }
    "private-eu-west-2b" = {
      subnet_id       = data.aws_subnet.private_subnets_b.id
      security_groups = [aws_security_group.ec2.id]
    }
    "private-eu-west-2c" = {
      subnet_id       = data.aws_subnet.private_subnets_c.id
      security_groups = [aws_security_group.ec2.id]
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

This:
- creates single-AZ solution with mount points in zone A only
- associates the mount point with a `aws_security_group.efs` resource, see Security Groups - Example 2
- uses the default burstable throughput mode with transition to IA (archive not supported in this mode)

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
      security_groups = [aws_security_group.efs.id]
    }
  }
  name = "efs2"
  tags = local.tags
}

output "efs2_dns_name" {
  description = "EFS DNS name"
  value = module.efs2.file_system.dns_name
}
```

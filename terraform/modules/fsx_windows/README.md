# FSX Windows File System Module

Pretty much a straight wrapper for the fsx resource but retrieves credentials for domain join.

## Example Usage

See <https://github.com/ministryofjustice/modernisation-platform-configuration-management> repo
for ansible code for mounting on linux server (filesystems role).

If joining on Windows server, example powershell:
```
NB: if manually testing, don't run this command under Administrator.
New-PSDrive -Name "D" -PSProvider "FileSystem" -Root "\\amznfsxf09lugmi.azure.noms.root\share" -Persist -Scope Global
```

NOTES:
- Use Single-AZ solution for non-production environments to save cost.
- Multi-AZ can only include 2 availability zones.
- Set `skip_final_backup true` to avoid issues deleting the resource
- See <https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/5343248588/AD+setup+for+fsx_windows+shared+drives> for specifics about AD setup and especially terraform values for joining the HMPP domain.

## Security Groups

The module does not create security groups. Unlike EFS, there is
authentication, but still good practice to limit network access.

###  Example 1 - Same security group as EC2

Use the same security group as the EC2 mounting the Windows File System.
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
resource "aws_security_group" "fsx" {
  name   = "fsx"
  vpc_id = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "fsx_ingress" {
  security_group_id        = aws_security_group.fsx.id
  type                     = "ingress"
  from_port                = 445
  to_port                  = 445
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
}
```

## Multi-AZ example

This:
- creates multi-AZ solution with mount points in eu-west-2a and eu-west-2b
- joins on-prem AD
- associates the mount point with a `aws_security_group.ec2` resource, see Security Groups - Example 1

```
module "fsx_windows1" {
  source = "../../modules/fsx_windows"

   preferred_availability_zone = "eu-west-2a"
   deployment_type             = "MULTI_AZ_1"
   name                        = "fsx_windows1"
   security_groups             = [aws_security_group.ec2.id]
   skip_final_backup           = true
   storage_capacity            = 32
   throughput_capacity         = 8

   subnet_ids = [
     data.aws_subnet.private_subnets_a.id,
     data.aws_subnet.private_subnets_b.id
   ]

   self_managed_active_directory = {
     dns_ips = [
       module.ip_addresses.mp_ip.ad-azure-dc-a,
       module.ip_addresses.mp_ip.ad-azure-dc-b,
     ]
     domain_name          = "azure.noms.root"
     username             = "svc_join_domain"
     password_secret_name = "/microsoft/AD/azure.noms.root/shared-passwords"
   }

   tags = local.tags
 }

output "fsx_windows1_dns_name" {
  description = "FSX Windows DNS name"
  value = module.fsx_windows1.windows_file_system.dns_name
}
```

## Single-AZ example

This:
- creates single-AZ solution with mount points in zone A only
- joins existing AWS AD (created outside of this module)

```
module "fsx_windows2" {
  source = "../../modules/fsx_windows"

   active_directory_id         = aws_directory_service_directory.this.id
   deployment_type             = "SINGLE_AZ_1"
   name                        = "fsx_windows2"
   security_groups             = ["aws_security_group.fsx.id"]
   skip_final_backup           = true
   storage_capacity            = 32
   subnet_ids                  = [ data.aws_subnet.private_subnets_a.id]
   throughput_capacity         = 8

   tags = local.tags
 }

output "fsx_windows2_dns_name" {
  description = "FSX Windows DNS name"
  value = module.fsx_windows2.windows_file_system.dns_name
}
```


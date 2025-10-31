resource "aws_fsx_windows_file_system" "mis_share" {
  active_directory_id = aws_directory_service_directory.mis_ad.id
  kms_key_id          = var.account_config.kms_keys.general_shared
  storage_capacity    = var.fsx_config.storage_capacity
  subnet_ids          = slice(var.account_config.private_subnet_ids, 0, 2)
  throughput_capacity = var.fsx_config.throughtput_capacity

  aliases                           = ["share.${var.app_name}-${var.env_name}.internal"]
  automatic_backup_retention_days   = 7
  copy_tags_to_backups              = true
  daily_automatic_backup_start_time = "03:00"
  deployment_type                   = "MULTI_AZ_1"
  preferred_subnet_id               = var.account_config.private_subnet_ids[0]
  security_group_ids                = [aws_security_group.fsx.id]

  tags = merge(
    local.tags,
    { Name = "${var.app_name}-${var.env_name}-fsx" }
  )
}

resource "aws_security_group" "fsx" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.app_name}-${var.env_name}-fsx"
  description = "Security group for FSx"
  vpc_id      = var.account_info.vpc_id
}

#############################################
### Allow all traffic within the security group
#############################################
resource "aws_vpc_security_group_ingress_rule" "fsx_internal_all" {
  security_group_id = aws_security_group.fsx.id

  referenced_security_group_id = aws_security_group.fsx.id
  ip_protocol                  = "-1" # All protocols
  description                  = "Allow all internal FSx traffic"
}

#############################################
### Allow SMB/WinRM traffic from the VPC CIDR
#############################################
resource "aws_vpc_security_group_ingress_rule" "fsx_smb_winrm_ingress" {
  for_each = {
    smb   = { from_port = 445, to_port = 445 }
    winrm = { from_port = 5985, to_port = 5985 }
  }

  security_group_id = aws_security_group.fsx.id

  description = "Allow ${each.key} traffic from the VPC CIDR to FSx"

  cidr_ipv4   = var.account_config.shared_vpc_cidr
  from_port   = each.value.from_port
  ip_protocol = "tcp"
  to_port     = each.value.to_port
}

#############################################
### Allow DNS egress traffic 
#############################################
resource "aws_vpc_security_group_egress_rule" "fsx_dns_egress" {
  for_each = toset(["tcp", "udp"])

  security_group_id = aws_security_group.fsx.id

  description = "Allow DNS egress traffic from FSx"

  cidr_ipv4   = var.account_config.shared_vpc_cidr
  from_port   = 53
  ip_protocol = each.value
  to_port     = 53
}

#############################################
### Allow AD egress traffic 
#############################################
resource "aws_vpc_security_group_egress_rule" "fsx_ad_egress" {
  for_each = {
    kerberos_tcp       = { from_port = 88, to_port = 88, protocol = "tcp" }
    kerberos_udp       = { from_port = 88, to_port = 88, protocol = "udp" }
    smb                = { from_port = 445, to_port = 445, protocol = "tcp" }
    password_tcp       = { from_port = 464, to_port = 464, protocol = "tcp" }
    password_udp       = { from_port = 464, to_port = 464, protocol = "udp" }
    ldap_tcp           = { from_port = 389, to_port = 389, protocol = "tcp" }
    ldap_udp           = { from_port = 389, to_port = 389, protocol = "udp" }
    ntp                = { from_port = 123, to_port = 123, protocol = "udp" }
    epmap              = { from_port = 135, to_port = 135, protocol = "tcp" }
    ldaps              = { from_port = 636, to_port = 636, protocol = "tcp" }
    global_catalog     = { from_port = 3268, to_port = 3268, protocol = "tcp" }
    global_catalog_ssl = { from_port = 3269, to_port = 3269, protocol = "tcp" }
    ad_web_services    = { from_port = 9389, to_port = 9389, protocol = "tcp" }
    rpc                = { from_port = 49152, to_port = 65535, protocol = "tcp" }
  }

  security_group_id = aws_security_group.fsx.id

  description = "Allow ${each.key} egress traffic from FSx to AD"

  referenced_security_group_id = aws_directory_service_directory.mis_ad.security_group_id
  from_port                    = each.value.from_port
  ip_protocol                  = each.value.protocol
  to_port                      = each.value.to_port
}

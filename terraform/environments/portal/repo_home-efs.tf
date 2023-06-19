
# resource "aws_security_group" "efs_sg" {
#
#   name        = "${local.application_name}-${local.environment}-repo_home-efs-security-group"
#   description = "Portal repo_home Product EFS Security Group"
#   vpc_id      = data.aws_vpc.shared.id
# }
#
# resource "aws_vpc_security_group_egress_rule" "efs_repo_home_outbound" {
#
#   security_group_id = aws_security_group.efs_sg.id
#   cidr_ipv4   = "0.0.0.0/0"
#   ip_protocol = "-1"
# }
#
# resource "aws_vpc_security_group_ingress_rule" "efs_repo_home_inbound" {
#
#   security_group_id = aws_security_group.efs_sg.id
#   referenced_security_group_id = aws_security_group.efs_sg.id
#   description = "EFS Rule inbound for repo_home"
#   from_port   = 2049
#   ip_protocol = "tcp"
#   to_port     = 2049
# }

resource "aws_efs_file_system" "efs" {

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-repo_home" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )

  lifecycle {
    prevent_destroy = true
  }

}


resource "aws_efs_mount_target" "target_a" {

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [for k, v in local.efs : aws_security_group.efs_product[k].id]
}

resource "aws_efs_mount_target" "target_b" {

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_b.id
  security_groups = [for k, v in local.efs : aws_security_group.efs_product[k].id]
}

resource "aws_efs_mount_target" "target_c" {

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_c.id
  security_groups = [for k, v in local.efs : aws_security_group.efs_product[k].id]
}

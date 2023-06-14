
resource "aws_security_group" "efs_sg" {
  
  name        = "${local.application_name}-${local.environment}-repo_home-efs-security-group"
  description = "Portal repo_home Product EFS Security Group"
  vpc_id      = data.aws_vpc.shared.id
}



resource "aws_efs_file_system" "efs" {

    performance_mode    = "generalPurpose"
    throughput_mode     = "bursting"
    encrypted           = "true"
    tags                = merge(
    local.tags,
    { "Name" = "${local.application_name}-repo_home" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
 }


resource "aws_efs_mount_target" "target" {
 
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.efs_sg.id]
}
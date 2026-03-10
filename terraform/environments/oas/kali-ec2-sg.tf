# resource "aws_security_group" "kali_sg" {
#   count = local.environment == "preproduction" ? 1 : 0

#   name        = "${local.application_name}-${local.environment}-ec2-kalisecurity-group"
#   description = "Kali EC2 Security Group"
#   vpc_id      = data.aws_vpc.shared.id

#   revoke_rules_on_delete = true

#   tags = merge(
#     local.tags,
#     { Name = "${local.application_name}-${local.environment}-ec2-security-group" }
#   )
# }



# ######################################
# ### EC2 EGRESS RULES for kali. ec2 instance
# ######################################
# resource "aws_security_group_rule" "kali_app" {
#   count = local.environment == "preproduction" ? 1 : 0

#   type                     = "egress"
#   security_group_id        = aws_security_group.kali_sg[0].id
#   from_port                = 1521
#   to_port                  = 1521
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.rds_sg[0].id
#   description              = "Database connections to OAS RDS"
# }



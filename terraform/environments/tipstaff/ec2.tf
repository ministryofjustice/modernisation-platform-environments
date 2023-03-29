# resource "aws_security_group" "tipstaff_dev_ec2_sc" {
#   name        = "ec2 security group"
#   description = "control access to the ec2 instance"
#   vpc_id      = data.aws_vpc.shared.id
# }

# resource "aws_security_group_rule" "ingress_traffic" {
#   for_each                 = local.application_data.ec2_sg_rules
#   description              = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#   from_port                = each.value.from_port
#   protocol                 = each.value.protocol
#   security_group_id        = aws_security_group.tipstaff_dev_ec2_sc.id
#   to_port                  = each.value.to_port
#   type                     = "ingress"
#   source_security_group_id = aws_security_group.tipstaff_dev_lb_sc.id
# }

# resource "aws_security_group_rule" "egress_traffic" {
#   for_each          = local.application_data.ec2_sg_rules
#   description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#   from_port         = each.value.from_port
#   protocol          = each.value.protocol
#   security_group_id = aws_security_group.tipstaff_dev_ec2_sc.id
#   to_port           = each.value.to_port
#   type              = "egress"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_instance" "tipstaff_ec2_instance_dev" {
#   instance_type               = local.application_data.accounts[local.environment].instance_type
#   ami                         = local.application_data.accounts[local.environment].ami_image_id
#   subnet_id                   = data.aws_subnet.private_subnets_a.id
#   vpc_security_group_ids      = [aws_security_group.tipstaff_dev_ec2_sc.id]
#   associate_public_ip_address = true
#   key_name                    = aws_key_pair.ec2_access_key.key_name
#   user_data                   = <<-EOF
#               <powershell>
#               Install-WindowsFeature -name Web-Server -IncludeManagementTools
#               New-Item -Path C:\inetpub\wwwroot\index.html -ItemType File -Value "Hello, World!" -Force
#               </powershell>
#               EOF
#   depends_on                  = [aws_security_group.tipstaff_dev_ec2_sc]
# }

# resource "aws_key_pair" "ec2_access_key" {
#   key_name   = "ec2_access_key"
#   public_key = jsondecode(data.aws_secretsmanager_secret_version.public_key.secret_string)["tipstaff_public_key"]
# }
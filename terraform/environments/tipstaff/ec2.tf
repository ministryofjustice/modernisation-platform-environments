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

# resource "aws_security_group" "rdp" {
#   name        = "rdp ec2 security group"
#   description = "Allow RDP connection"
#   vpc_id      = data.aws_vpc.shared.id

#   ingress {
#     from_port   = 3389
#     to_port     = 3389
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "codedeploy" {
#   name        = "CodeDeploy ec2 security group"
#   description = "Allow inbound traffic from CodeDeploy service"
#   vpc_id      = data.aws_vpc.shared.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = data.aws_ip_ranges.eu_codedeploy.cidr_blocks
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = data.aws_ip_ranges.eu_codedeploy.cidr_blocks
#   }
# }

# data "aws_ip_ranges" "eu_codedeploy" {
#   regions  = ["eu-west-2"]
#   services = ["codedeploy"]
# }

# resource "aws_instance" "tipstaff_ec2_instance" {
#   instance_type               = local.application_data.accounts[local.environment].instance_type
#   ami                         = local.application_data.accounts[local.environment].ami_image_id
#   subnet_id                   = data.aws_subnet.public_subnets_a.id
#   vpc_security_group_ids      = [aws_security_group.tipstaff_dev_ec2_sc.id, aws_security_group.rdp.id]
#   associate_public_ip_address = true
#   key_name                    = aws_key_pair.ec2_access_key.key_name
#   iam_instance_profile        = aws_iam_instance_profile.codedeploy_instance_profile.name
#   user_data                   = <<-EOF
#               <powershell>
#               Install-WindowsFeature -name Web-Server -IncludeManagementTools
#               Set-Location -Path "C:\"
#               Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
#               Invoke-WebRequest -Uri https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/codedeploy-agent.msi -OutFile codedeploy-agent.msi
#               Start-Process -FilePath msiexec.exe -ArgumentList "/i", "codedeploy-agent.msi", "/quiet" -Wait
#               Set-Service -Name codedeployagent -StartupType "Automatic"
#               Start-Service -Name codedeployagent
#               </powershell>
#               EOF
#   depends_on                  = [aws_security_group.tipstaff_dev_ec2_sc]
#   tags = {
#     Name = "tipstaff-ec2"
#   }
# }


# resource "aws_key_pair" "ec2_access_key" {
#   key_name   = "ec2_access_key"
#   public_key = jsondecode(data.aws_secretsmanager_secret_version.public_key.secret_string)["tipstaff_public_key"]
# }

# resource "aws_iam_role" "ec2_role" {
#   name = "ec2-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy" "ec2_role_policy" {
#   name = "ec2-policy"
#   role = aws_iam_role.ec2_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "codedeploy:*",
#           "s3:*"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }

# resource "aws_iam_instance_profile" "codedeploy_instance_profile" {
#   name = "codedeploy-instance-profile"
#   role = aws_iam_role.ec2_role.name
# }
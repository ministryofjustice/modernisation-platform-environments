# # terraform/test_cleanup/main.tf

# # ----- Inputs -----
# variable "region" {
#   type    = string
#   default = "eu-west-2"
# }

# variable "az" {
#   type    = string
#   default = "eu-west-2a"
# }

# # Optional override if you want to force a specific subnet later:
# variable "subnet_id" {
#   type    = string
#   default = ""
# }

# # Tag helper
# locals {
#   common_tags = {
#     Name       = "cleanup-test"
#     purpose    = "cleanup-test"
#     owner      = "example-development"
#     managed_by = "terraform"
#     delete_me  = "true"
#   }
# }

# # ----- Source AMI (public) -----
# data "aws_ssm_parameter" "al2023" {
#   name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
# }

# # ---- Auto-discover a subnet in the target AZ (since there is no default VPC) ----
# # If subnet_id is not provided, we pick the first subnet found in var.az.
# data "aws_subnets" "in_az" {
#   filter {
#     name   = "availability-zone"
#     values = [var.az]
#   }
# }

# locals {
#   chosen_subnet_id = var.subnet_id != "" ? var.subnet_id : (length(data.aws_subnets.in_az.ids) > 0 ? data.aws_subnets.in_az.ids[0] : "")
# }

# # Guard: fail early with a clear message if no subnet is found in that AZ.
# resource "null_resource" "assert_subnet_present" {
#   triggers = {
#     chosen_subnet_id = local.chosen_subnet_id
#   }

#   lifecycle {
#     precondition {
#       condition     = local.chosen_subnet_id != ""
#       error_message = "No subnet found in availability zone ${var.az}. Provide -var subnet_id=... or choose an AZ that has subnets."
#     }
#   }
# }

# # Look up the subnet to get its VPC ID
# data "aws_subnet" "chosen" {
#   id = local.chosen_subnet_id
# }

# # Minimal SG in that VPC (no ingress, allow all egress)
# resource "aws_security_group" "cleanup_test_sg" {
#   name        = "cleanup-test-sg"
#   description = "Egress-only SG for cleanup-test instance"
#   vpc_id      = data.aws_subnet.chosen.vpc_id

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = merge(local.common_tags, { Name = "cleanup-test-sg" })
# }

# # ----- AMIs you own (copies) -----
# resource "aws_ami_copy" "a1_unreferenced_unused_old" {
#   name              = "cleanup-test-unref-unused-old"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (unreferenced, unused, old)"
#   tags              = local.common_tags
# }

# # WAIT: 3 minutes before creating the next AMIs (to establish age gap)
# resource "time_sleep" "three_min_gap" {
#   depends_on      = [aws_ami_copy.a1_unreferenced_unused_old]
#   create_duration = "3m"
# }

# # Referenced in code (excluded when -c)
# # The AMI cleanup script greps *.tf for: ami_name = "<value>"
# locals {
#   ami_name = "cleanup-test-ref-unused-old"
# }

# resource "aws_ami_copy" "a2_referenced_unused_old" {
#   depends_on        = [time_sleep.three_min_gap]
#   name              = local.ami_name
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (referenced in code, unused, old)"
#   tags              = local.common_tags
# }

# # AwsBackup-named (excluded by default)
# resource "aws_ami_copy" "a3_backup_named_old" {
#   depends_on        = [time_sleep.three_min_gap]
#   name              = "AwsBackup cleanup-test-backup-old"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (AwsBackup-named, old)"
#   tags              = local.common_tags
# }

# # In-use AMI (launch instance => excluded by AMI cleanup)
# resource "aws_ami_copy" "a4_unreferenced_inuse_old" {
#   depends_on        = [time_sleep.three_min_gap]
#   name              = "cleanup-test-unref-inuse-old"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (unreferenced, in-use, old)"
#   tags              = local.common_tags
# }

# resource "aws_instance" "inuse_tiny" {
#   depends_on                  = [null_resource.assert_subnet_present]
#   ami                         = aws_ami_copy.a4_unreferenced_inuse_old.id
#   instance_type               = "t3.micro"
#   subnet_id                   = local.chosen_subnet_id
#   vpc_security_group_ids      = [aws_security_group.cleanup_test_sg.id]
#   associate_public_ip_address = false

#   tags = merge(local.common_tags, { Name = "cleanup-test-inuse-instance" })
# }

# # New AMI (too new when minutes-based gate is used)
# resource "aws_ami_copy" "a5_unreferenced_unused_new" {
#   name              = "cleanup-test-unref-unused-new"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (unreferenced, unused, new)"
#   tags              = local.common_tags
# }

# # ----- EBS volumes -----
# # V1: Unattached (candidate)
# resource "aws_ebs_volume" "v1_unattached_old" {
#   availability_zone = var.az
#   size              = 1
#   type              = "gp3"
#   tags              = merge(local.common_tags, { Name = "cleanup-test-unattached-old" })
# }

# # WAIT: 3 minutes before creating the next volumes (to establish age gap)
# resource "time_sleep" "three_min_gap_vol" {
#   depends_on      = [aws_ebs_volume.v1_unattached_old]
#   create_duration = "3m"
# }

# # V2: Attached (excluded by EBS cleanup)
# resource "aws_ebs_volume" "v2_attached_old" {
#   depends_on        = [time_sleep.three_min_gap_vol, aws_instance.inuse_tiny]
#   availability_zone = var.az
#   size              = 1
#   type              = "gp3"
#   tags              = merge(local.common_tags, { Name = "cleanup-test-attached-old" })
# }

# resource "aws_volume_attachment" "attach_v2" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.v2_attached_old.id
#   instance_id = aws_instance.inuse_tiny.id
# }

# # V3: Unattached new (too new when minutes-based gate is used)
# resource "aws_ebs_volume" "v3_unattached_new" {
#   availability_zone = var.az
#   size              = 1
#   type              = "gp3"
#   tags              = merge(local.common_tags, { Name = "cleanup-test-unattached-new" })
# }

# # V4: Unattached with snapshot link scenario
# resource "aws_ebs_volume" "v4_unattached_for_snapshot" {
#   availability_zone = var.az
#   size              = 1
#   type              = "gp3"
#   tags              = merge(local.common_tags, { Name = "cleanup-test-unattached-old-from-snapshot" })
# }

# resource "aws_ebs_snapshot" "snap_v4" {
#   volume_id   = aws_ebs_volume.v4_unattached_for_snapshot.id
#   description = "cleanup-test snapshot"
#   tags        = merge(local.common_tags, { Name = "cleanup-test-snapshot" })
# }

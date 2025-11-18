# # terraform/test_cleanup/main.tf

# # This file is to test the two scripts below,
# #
# #    1) AMI cleaner (ami_cleanup.sh)
# #       - Deletes AMIs that are:
# #         • old enough (months OR minute test-mode)
# #         • NOT referenced in code (when -c is used)
# #         • NOT used by any running instance
# #         • NOT protected by name/tag (e.g., AwsBackup, Retain=true, Backup=true)

# #
# #    2) EBS cleaner (ebs_cleanup.sh)
# #       - Deletes UNATTACHED volumes older than the age gate.
# #
# # 🧹 Snapshots fallback (in workflow)
# #    After AMI deletion, the workflow attempts a SECOND PASS against any mapped
# #    snapshots in case AWS did not remove some (timing/consistency). It skips if:
# #      • AMI still exists (safety)
# #      • Snapshot is already gone
# #      • Snapshot is AwsBackup or has Retain/Backup=true tags


# # ----- Inputs -----
# variable "region" {
#   type    = string
#   default = "eu-west-2"
# }

# variable "az" {
#   type    = string
#   default = "eu-west-2a"
# }

# variable "subnet_id" {
#   type    = string
#   default = ""
# }

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

# data "aws_subnets" "in_az" {
#   filter {
#     name   = "availability-zone"
#     values = [var.az]
#   }
# }

# locals {
#   chosen_subnet_id = var.subnet_id != "" ? var.subnet_id : (length(data.aws_subnets.in_az.ids) > 0 ? data.aws_subnets.in_az.ids[0] : "")
# }

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

# data "aws_subnet" "chosen" {
#   id = local.chosen_subnet_id
# }

# resource "aws_security_group" "test_cleanup_test_sg" {
#   name        = "test-cleanup-test-sg"
#   description = "Egress-only SG for cleanup-test instance"
#   vpc_id      = data.aws_subnet.chosen.vpc_id

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = merge(local.common_tags, { Name = "test-cleanup-test-sg" })
# }

# # ----- AMIs you own (copies) -----

# # a1_unreferenced_unused_old
# # Expected: DELETE when the workflow runs
# # Why: Owned, old enough (see the sleep below), not in use, not referenced in code,
# #      not protected by “AwsBackup” name or retention tags.
# resource "aws_ami_copy" "a1_unreferenced_unused_old" {
#   name              = "cleanup-test-unref-unused-old"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (unreferenced, unused, old)"
#   tags              = local.common_tags
# }

# # Wait 3 minutes to establish an age gap for “old enough” vs “new”.
# # In CI test-mode, the YAML passes a minute-based threshold (e.g., 0s),
# # so resources created BEFORE this sleep are “older” than those created AFTER.
# resource "time_sleep" "three_min_gap" {
#   depends_on      = [aws_ami_copy.a1_unreferenced_unused_old]
#   create_duration = "0s"
# }

# # This AMI is *referenced in code* via locals.ami_name (see locals just below).
# # When the workflow runs with -c, the AMI cleanup greps *.tf for `ami_name = "<value>"`
# # and EXCLUDES it from deletion.
# locals {
#   ami_name = "cleanup-test-ref-unused-old"
# }

# # a2_referenced_unused_old (Its not launched or attached)
# # Expected: KEEP (excluded when -c is passed to the cleaner)
# # Why: The name is referenced in code (locals.ami_name), so -c filters it out.
# resource "aws_ami_copy" "a2_referenced_unused_old" {
#   depends_on        = [time_sleep.three_min_gap]
#   name              = local.ami_name
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (referenced in code, unused, old)"
#   tags              = local.common_tags
# }

# # a3_backup_named_old
# # Expected: KEEP (protected by AwsBackup name)
# # Why: The workflow guards AMIs whose Name starts with/contains “AwsBackup”.
# resource "aws_ami_copy" "a3_backup_named_old" {
#   depends_on        = [time_sleep.three_min_gap]
#   name              = "AwsBackup cleanup-test-backup-old"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (AwsBackup-named, old)"
#   tags              = local.common_tags
# }

# # a4_unreferenced_inuse_old (+ instance below)
# # Expected: KEEP (marked “in use”)
# # Why: The workflow checks for any running instances launched from an AMI.
# #      If found, that AMI is excluded from deletion for safety.
# resource "aws_ami_copy" "a4_unreferenced_inuse_old" {
#   depends_on        = [time_sleep.three_min_gap]
#   name              = "cleanup-test-unref-inuse-old"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (unreferenced, in-use, old)"
#   tags              = local.common_tags
# }

# # This instance is launched from a4_… which makes that AMI “in use”.
# resource "aws_instance" "inuse_tiny" {
#   depends_on                  = [null_resource.assert_subnet_present]
#   ami                         = aws_ami_copy.a4_unreferenced_inuse_old.id
#   instance_type               = "t3.micro"
#   subnet_id                   = local.chosen_subnet_id
#   vpc_security_group_ids      = [aws_security_group.test_cleanup_test_sg.id]
#   associate_public_ip_address = false

#   tags = merge(local.common_tags, { Name = "cleanup-test-inuse-instance" })
# }

# # a5_unreferenced_unused_new
# # Expected: KEEP in minute-based tests (too NEW to pass the test-mode age gate)
# # Why: Created after the 3-minute gap; in test-mode with age_minutes=3
# resource "aws_ami_copy" "a5_unreferenced_unused_new" {
#   name              = "cleanup-test-unref-unused-new"
#   source_ami_id     = data.aws_ssm_parameter.al2023.value
#   source_ami_region = var.region
#   description       = "cleanup-test AMI (unreferenced, unused, new)"
#   tags              = local.common_tags
# }

# # ----- EBS volumes -----

# # V1: Unattached OLD volume → Candidate for deletion by EBS cleaner.
# resource "aws_ebs_volume" "v1_unattached_old" {
#   availability_zone = var.az
#   size              = 1
#   type              = "gp3"
#   tags              = merge(local.common_tags, { Name = "cleanup-test-unattached-old" })
# }

# # Age gap to separate “old” (V1) from later resources (V2, V3)
# resource "time_sleep" "three_min_gap_vol" {
#   depends_on      = [aws_ebs_volume.v1_unattached_old]
#   create_duration = "0s"
# }

# # V2: ATTACHED volume → Excluded by EBS cleaner.
# # The EBS cleaner only deletes *unattached* volumes.
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

# # V3: Unattached NEW volume → Typically below the minute-based age cutoff,
# # therefore so its kept during minute-based tests.
# resource "aws_ebs_volume" "v3_unattached_new" {
#   availability_zone = var.az
#   size              = 1
#   type              = "gp3"
#   tags              = merge(local.common_tags, { Name = "cleanup-test-unattached-new" })
# }
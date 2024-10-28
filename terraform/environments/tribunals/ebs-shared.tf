# resource "aws_ebs_volume" "tribunals-ebs" {
#   availability_zone = "eu-west-2a"
#   type              = "gp2"
#   size              = 10

#   tags = merge(
#     local.tags,
#     {
#       Name = "tribunals-all-storage"
#     }
#   )
# }

# resource "aws_ebs_volume" "tribunals-backup-ebs" {
#   availability_zone = "eu-west-2b"
#   type              = "gp2"
#   size              = 10

#   tags = merge(
#     local.tags,
#     {
#       Name = "tribunals-backup-storage"
#     }
#   )
# }

# resource "aws_volume_attachment" "tribunals-backup-ebs-attachment" {
#   device_name = "/dev/sdf"
#   volume_id   = aws_ebs_volume.tribunals-backup-ebs.id
#   instance_id = aws_instance.tribunals-backup.id
# }
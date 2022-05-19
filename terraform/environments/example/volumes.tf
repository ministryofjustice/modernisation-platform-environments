# Volumes built for use by EC2.
                  
 resource "aws_ebs_volume" "ebs_volume" {
              # device_name = "/dev/sdf"
              availability_zone = local.app_variables.accounts[local.environment].region
              type = "gp3"
              size = 50
              throughput  = 200
              encrypted   = true
              # kms_key_id  = aws_kms_key.this.arn
              tags = {
                Name = "ebs-data-volume"
              }
}

 resource "aws_volume_attachment" "mountvolumetoec2" {
  # device_name = "/dev/sdb"
  instance_id = aws_instance.develop.id
  volume_id = aws_volume_attachment.mountvolumetoec2.id
 }
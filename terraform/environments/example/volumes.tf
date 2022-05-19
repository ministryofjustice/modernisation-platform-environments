# Volumes built for use by EC2.
                  
 resource "aws_ebs_volume" "ebs_volume" {
              availability_zone = "${local.app_variables.accounts[local.environment].region}a"
              #availability_zone = "eu-west-2a"
              type              = "gp3"
              size              = 50
              throughput        = 200
              encrypted         = true
              # kms_key_id  = aws_kms_key.this.arn
              tags = {
                Name = "ebs-data-volume"
              }
            
              depends_on = [aws_instance.develop]
}
# Attach to the EC2
 resource "aws_volume_attachment" "mountvolumetoec2" {
  device_name = "/dev/sdb"
  instance_id = aws_instance.develop.id
  volume_id = aws_ebs_volume.ebs_volume.id
}
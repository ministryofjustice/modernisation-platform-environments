#--Instances would not book with a CMK and time to debug was not available. Ideally this needs to be
#--debugged and migrated on to a CMK! - AW
data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}

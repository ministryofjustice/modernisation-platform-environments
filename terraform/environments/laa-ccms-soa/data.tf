#--TEMPORARY. SHOULD USE A CMK. AW
data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}

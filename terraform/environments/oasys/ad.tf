variable "instance_profile_policies" {
  type        = string
  description = "A list of managed IAM policy document ARNs to be attached to the database instance profile"
  default     = " "
}
/*resource "aws_iam_role_policy_attachment" "this" {
policy = { 
  var.instance_profile_policies
  }
}*/

resource "aws_subnet" "public_a" {
  public = subnetaws_subnet.public_a
  vpc_id = vpc

}

variable "default_policy_arn" {
  description = "Default policy ARN to attach"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

